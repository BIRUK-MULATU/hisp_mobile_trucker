import 'dart:convert';

import '../../features/data_entry/domain/entities/outlier_stats.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';

/// Builds a recent-history snapshot for one form instance's org unit and
/// judges freshly typed values against it — the statistical companion to
/// [ValidationService]'s rule check. Entirely local once the snapshot is
/// in hand: [fetchHistory] is the only method that touches the network,
/// and it caches its last answer so the check keeps working offline.
///
/// The server's own `/api/outlierDetection` endpoint is deliberately NOT
/// used: it only scores values already stored server-side and cannot
/// judge the value a user is typing right now.
class OutlierDetectionService {
  OutlierDetectionService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient? _api;

  /// How far back the history window reaches. ~25 months so a monthly
  /// dataset has two full years of the same season to compare against.
  static const _historyWindowDays = 770;

  static String cacheKey({
    required String dataSetUid,
    required String orgUnitUid,
    required String attributeOptionComboUid,
  }) =>
      'outlierHistory_${dataSetUid}_${orgUnitUid}_$attributeOptionComboUid';

  /// Map key for one cell's stats: `<dataElementUid>_<cocUid>`.
  static String statsKey(String dataElementUid, String cocUid) =>
      '${dataElementUid}_$cocUid';

  /// Pull the last [_historyWindowDays] of this dataset's values at this
  /// org unit and reduce each cell to an [OutlierStats]. Tries the
  /// server first; on any failure (offline, error) falls back to the
  /// cached snapshot from the previous successful fetch. Returns an
  /// empty map when neither is available — the caller treats that as
  /// "checking disabled", never an error.
  ///
  /// [excludePeriod] drops the form's own period from the history so
  /// the "previous entries" shown next to a cell never include the
  /// value the user is typing right now.
  Future<Map<String, OutlierStats>> fetchHistory({
    required String dataSetUid,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    String? excludePeriod,
  }) async {
    final key = cacheKey(
      dataSetUid: dataSetUid,
      orgUnitUid: orgUnitUid,
      attributeOptionComboUid: attributeOptionComboUid,
    );

    final api = _api;
    if (api != null) {
      try {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: _historyWindowDays));
        final res =
            await api.get('/api/dataValueSets.json', queryParameters: {
          'dataSet': dataSetUid,
          'orgUnit': orgUnitUid,
          'startDate': _fmt(start),
          'endDate': _fmt(now),
        });
        final values = ((res.data as Map<String, dynamic>)['dataValues']
                    as List? ??
                const [])
            .cast<Map<String, dynamic>>();
        final series = _groupNumericByCell(
          values,
          attributeOptionComboUid,
          excludePeriod: excludePeriod,
        );
        final stats = <String, OutlierStats>{};
        series.forEach((cell, entries) {
          final s = OutlierStats.fromHistory(entries);
          if (s != null) stats[cell] = s;
        });
        await _db.setSyncInfo(
          key,
          jsonEncode({
            'cachedAt': DateTime.now().toIso8601String(),
            'stats': {for (final e in stats.entries) e.key: e.value.toJson()},
          }),
        );
        log.i('[outlier] history for $dataSetUid/$orgUnitUid: '
            '${stats.length} cell(s) from ${values.length} value(s)');
        return stats;
      } catch (e) {
        log.w('[outlier] live history fetch failed ($e) — trying cache');
      }
    }
    return _readCache(key);
  }

  /// Judge one typed value against a cell's history. Returns null when
  /// it is within range OR the history is too thin / too flat to make a
  /// meaningful call (`n < 3`, or a zero spread the algorithm needs).
  static OutlierVerdict? judge(
    String rawValue,
    OutlierStats s,
    OutlierConfig cfg,
  ) {
    final v = double.tryParse(rawValue.trim());
    if (v == null || !v.isFinite) return null;
    if (s.n < 3) return null;
    final t = cfg.threshold <= 0 ? 3.0 : cfg.threshold;

    double lower;
    double upper;
    double score;

    switch (cfg.algorithm) {
      case OutlierAlgorithm.zScore:
        if (s.stdDev <= 0) return null;
        lower = s.mean - t * s.stdDev;
        upper = s.mean + t * s.stdDev;
        score = (v - s.mean).abs() / s.stdDev;
      case OutlierAlgorithm.modifiedZScore:
        if (s.mad <= 0) return null;
        final spread = s.mad / 0.6745;
        lower = s.median - t * spread;
        upper = s.median + t * spread;
        score = (v - s.median).abs() / spread;
      case OutlierAlgorithm.minMax:
        final guard = s.stdDev > 0 ? t * s.stdDev : 0.0;
        lower = s.min - guard;
        upper = s.max + guard;
        final beyond = v < lower
            ? lower - v
            : v > upper
                ? v - upper
                : 0.0;
        score = s.stdDev > 0 ? beyond / s.stdDev : (beyond > 0 ? double.infinity : 0);
    }

    final isOutlier = v < lower || v > upper;
    if (!isOutlier) return null;

    return OutlierVerdict(
      value: v,
      lowerBound: lower,
      upperBound: upper,
      score: score,
      typical: s.median,
      historicalMin: s.min,
      historicalMax: s.max,
      n: s.n,
      recent: s.recent.take(recentEntryCount).toList(),
    );
  }

  /// How many of the cell's newest values the warning dialog lists.
  static const recentEntryCount = 3;

  // ── internals ────────────────────────────────────────────────────

  Future<Map<String, OutlierStats>> _readCache(String key) async {
    final raw = await _db.getSyncInfo(key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final stats = (json['stats'] as Map<String, dynamic>? ?? const {});
      return {
        for (final e in stats.entries)
          e.key: OutlierStats.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (e) {
      log.e('[outlier] cached history unreadable: $e');
      return const {};
    }
  }

  /// `<de>_<coc>` → the historical `(period, value)` rows, keeping only
  /// rows under the same attributeOptionCombo the form is scoped to
  /// and (optionally) dropping the form's own period. Rows without a
  /// period id still count toward the summary stats, just with an
  /// empty label.
  static Map<String, List<HistoryEntry>> _groupNumericByCell(
    List<Map<String, dynamic>> values,
    String attributeOptionComboUid, {
    String? excludePeriod,
  }) {
    final out = <String, List<HistoryEntry>>{};
    for (final v in values) {
      final aoc = v['attributeOptionCombo'] as String?;
      if (aoc != null && aoc != attributeOptionComboUid) continue;
      final de = v['dataElement'] as String?;
      final coc = v['categoryOptionCombo'] as String?;
      if (de == null || coc == null) continue;
      final period = v['period'] as String? ?? '';
      if (excludePeriod != null && period == excludePeriod) continue;
      final n = double.tryParse(v['value']?.toString() ?? '');
      if (n == null || !n.isFinite) continue;
      (out[statsKey(de, coc)] ??= []).add(HistoryEntry(value: n, periodId: period));
    }
    return out;
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

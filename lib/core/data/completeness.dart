import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../metadata/category_option_combo.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'audit_log_store.dart';
import 'period_access.dart';

/// Complete / incomplete a dataset for a form instance. Same offline
/// pattern as data values (sync-stated, push-first), simpler (no
/// per-cell conflict — a registration is one boolean fact).
class CompletenessStore {
  CompletenessStore(this._db)
      : _clock = PeriodAccess(_db),
        _auditLog = AuditLogStore(_db);

  final AppDatabase _db;
  final PeriodAccess _clock;
  final AuditLogStore _auditLog;

  /// Mark a form complete or incomplete locally, pending push.
  Future<void> setComplete({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required bool completed,
    String? storedBy,
  }) async {
    final previous = await statusOf(
      dataSetUid: dataSetUid,
      period: period,
      orgUnitUid: orgUnitUid,
      attributeOptionComboUid: attributeOptionComboUid,
    );
    final now = await _clock.effectiveNow();
    await _db.transaction(() async {
      await _db
          .into(_db.completeDataSetRegistrationsTable)
          .insertOnConflictUpdate(
            CompleteDataSetRegistrationsTableCompanion.insert(
              dataSetUid: dataSetUid,
              period: period,
              orgUnitUid: orgUnitUid,
              attributeOptionComboUid: attributeOptionComboUid,
              completed: completed,
              storedBy: Value(storedBy),
              // effectiveNow (monotonic high-water clock), NOT
              // DateTime.now() — same rule as DataValueStore, so a
              // backdated device can't fake completion timestamps.
              date: now,
              syncState: SyncState.pending,
              lastModified: now,
            ),
          );
      await _auditLog.recordCompleteness(
        dataSetUid: dataSetUid,
        period: period,
        orgUnitUid: orgUnitUid,
        attributeOptionComboUid: attributeOptionComboUid,
        previousCompleted: previous?.completed,
        completed: completed,
        modifiedBy: storedBy,
        modifiedAt: now,
      );
    });
  }

  Future<CompleteDataSetRegistration?> statusOf({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
  }) {
    return (_db.select(_db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(dataSetUid) &
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid)))
        .getSingleOrNull();
  }

  Future<List<CompleteDataSetRegistration>> pending() =>
      (_db.select(_db.completeDataSetRegistrationsTable)
            ..where((t) => t.syncState.equals(SyncState.pending.index)))
          .get();

  /// Apply a `completed == true` registration pulled from the server.
  /// NEVER clobbers unsynced local work: it writes only when there is
  /// no local row, or the local row is already `synced` — a pending or
  /// error registration on this device stays as the source of truth
  /// until it has had its turn to push (same rule as
  /// DataValueSync._pullAndResolve). Returns true if a row was written.
  Future<bool> applyServerComplete({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required DateTime date,
    String? storedBy,
  }) async {
    final local = await statusOf(
      dataSetUid: dataSetUid,
      period: period,
      orgUnitUid: orgUnitUid,
      attributeOptionComboUid: attributeOptionComboUid,
    );
    if (local != null && local.syncState != SyncState.synced) return false;
    if (local != null && local.completed) return false; // already there
    await _db.into(_db.completeDataSetRegistrationsTable).insertOnConflictUpdate(
          CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: dataSetUid,
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            completed: true,
            storedBy: Value(storedBy),
            date: date,
            syncState: SyncState.synced,
            lastModified: date,
          ),
        );
    return true;
  }
}

/// Push/pull completeness registrations. Holds the ApiClient.
class CompletenessSync {
  CompletenessSync(this._db, this._api) : _store = CompletenessStore(_db);

  final AppDatabase _db;
  final ApiClient _api;
  final CompletenessStore _store;

  /// Push all pending registrations. completeDataSetRegistrations takes
  /// a list; completed=true POSTs, completed=false DELETEs.
  Future<int> pushPending() async {
    final pending = await _store.pending();
    if (pending.isEmpty) return 0;

    var ok = 0;
    for (final r in pending) {
      try {
        if (r.completed) {
          await _api.post('/api/completeDataSetRegistrations', data: {
            'completeDataSetRegistrations': [
              {
                'dataSet': r.dataSetUid,
                'period': r.period,
                'organisationUnit': r.orgUnitUid,
                'attributeOptionCombo': r.attributeOptionComboUid,
              }
            ]
          });
        } else {
          await _api.delete('/api/completeDataSetRegistrations',
              queryParameters: {
                'ds': r.dataSetUid,
                'pe': r.period,
                'ou': r.orgUnitUid,
                // Non-default attribute combos must be addressed
                // explicitly or the server un-completes the wrong
                // registration; the default combo is resolved
                // server-side, so it sends no cc/cp (also covers a
                // combo missing from the local metadata cache).
                ...await _attributeParams(r.attributeOptionComboUid),
              });
        }
        await _markSynced(r);
        ok++;
      } on DioException catch (e) {
        // A 409 is a server VERDICT (conflicts in the body), not a
        // transport failure — retrying the same registration forever
        // can't succeed, so settle it as an error the UI can surface.
        final data = e.response?.data;
        if (e.response?.statusCode == 409 && data is Map<String, dynamic>) {
          final summary =
              (data['response'] ?? data) as Map<String, dynamic>;
          final conflicts = (summary['conflicts'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          final why = conflicts.isNotEmpty
              ? conflicts.map((c) => c['value']).join('; ')
              : (data['message'] ?? 'Rejected by server').toString();
          log.w('[completeness] ${r.dataSetUid}/${r.period} rejected: $why');
          await _markError(r, why);
        } else {
          log.e('[completeness] push error for ${r.dataSetUid}/${r.period}: '
              '${e.message}');
          // leave pending, retry later
        }
      }
    }
    log.i('[completeness] pushed $ok/${pending.length}');
    return ok;
  }

  Future<Map<String, String>> _attributeParams(String aocUid) =>
      resolveCcCpParams(_db, aocUid);

  /// PULL the server's completion state for [orgUnitUids] since [since]
  /// and mirror `completed == true` rows locally (as `synced`, without
  /// touching unsynced local work — see
  /// [CompletenessStore.applyServerComplete]). Lets the "expected
  /// reports" list drop a report finished on the web or another device.
  /// Best-effort: any failure just leaves the local view as-is.
  /// Returns how many rows were newly mirrored.
  Future<int> pullRecent({
    required List<String> orgUnitUids,
    required DateTime since,
  }) async {
    if (orgUnitUids.isEmpty) return 0;
    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final duplicates = await duplicateDefaultComboUids(_db);
    var applied = 0;
    // Cap the org unit fan-out per request — a facility user has only a
    // handful, but stay safe against a wide capture scope.
    for (var i = 0; i < orgUnitUids.length; i += 40) {
      final slice = orgUnitUids.sublist(
          i, i + 40 > orgUnitUids.length ? orgUnitUids.length : i + 40);
      final Response res;
      try {
        res = await _api.get('/api/completeDataSetRegistrations.json',
            queryParameters: {
              'orgUnit': slice,
              'startDate': fmt(since),
              'endDate': fmt(DateTime.now()),
              'fields': 'dataSet,period,organisationUnit,attributeOptionCombo,'
                  'completed,date',
            });
      } on DioException catch (e) {
        log.w('[completeness] pullRecent failed: ${e.message}');
        return applied;
      }
      final regs = ((res.data as Map<String, dynamic>)[
                  'completeDataSetRegistrations'] as List? ??
              const [])
          .cast<Map<String, dynamic>>();
      for (final r in regs) {
        if (r['completed'] == false) continue;
        var aoc = r['attributeOptionCombo'] as String?;
        if (aoc == null || duplicates.contains(aoc)) {
          aoc = canonicalDefaultComboUid;
        }
        final ds = r['dataSet'] as String?;
        final pe = r['period'] as String?;
        final ou = r['organisationUnit'] as String?;
        if (ds == null || pe == null || ou == null) continue;
        final date =
            DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now();
        if (await _store.applyServerComplete(
          dataSetUid: ds,
          period: pe,
          orgUnitUid: ou,
          attributeOptionComboUid: aoc,
          date: date,
        )) {
          applied++;
        }
      }
    }
    if (applied > 0) {
      log.i('[completeness] mirrored $applied server completion(s)');
    }
    return applied;
  }

  Future<void> _markSynced(CompleteDataSetRegistration r) =>
      _writeState(r, SyncState.synced);

  Future<void> _markError(CompleteDataSetRegistration r, String error) =>
      _writeState(r, SyncState.error, error);

  Future<void> _writeState(CompleteDataSetRegistration r, SyncState state,
      [String? error]) {
    return (_db.update(_db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(r.dataSetUid) &
              t.period.equals(r.period) &
              t.orgUnitUid.equals(r.orgUnitUid) &
              t.attributeOptionComboUid.equals(r.attributeOptionComboUid)))
        .write(CompleteDataSetRegistrationsTableCompanion(
      syncState: Value(state),
      syncError: Value(error),
    ));
  }
}

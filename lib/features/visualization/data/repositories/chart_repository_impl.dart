import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_config.dart';

/// A data element together with its category option combos, so the
/// builder can expand a "Details Only" selection into `de.coc`
/// operand items without another round-trip.
class DataElementWithCocs {
  final ChartItemRef ref;
  final List<ChartItemRef> cocs;

  const DataElementWithCocs({required this.ref, required this.cocs});
}

/// Result of an offline-aware chart load — see [ChartRepositoryImpl.loadChart].
class ChartLoadResult {
  final AnalyticsData data;

  /// True when [data] came from the local cache rather than a live
  /// query — the UI must say so, since it can be stale.
  final bool isFromCache;

  /// When [isFromCache], the moment that result was captured.
  final DateTime? cachedAt;

  const ChartLoadResult(
      {required this.data, required this.isFromCache, this.cachedAt});
}

/// The chart builder's data side: metadata pickers straight from the
/// API (the builder itself is online-only — picking dimensions needs
/// the server), the analytics query built from a ChartConfig, and the
/// saved-chart list persisted as JSON under one syncInfo key in the
/// per-user database (no schema change, so no migration).
///
/// VIEWING a saved chart is NOT online-only: [loadChart] caches every
/// successful query result (also under syncInfo, one key per chart) so
/// reopening it offline still shows the last-known numbers.
class ChartRepositoryImpl {
  static const savedChartsKey = 'savedCharts';
  static String _cacheKey(String chartId) => 'chartCache_$chartId';

  final SessionService _session;
  final ApiClient? _apiOverride;

  ChartRepositoryImpl({SessionService? session, ApiClient? api})
      : _session = session ?? AppSession.instance.service,
        _apiOverride = api;

  AppDatabase get _db => _session.db;

  ApiClient get _api {
    final api = _apiOverride ?? AppSession.instance.api;
    if (api == null) {
      throw const NetworkException(
          message: 'Charts need a connection to the server.');
    }
    return api;
  }

  // ── Metadata for the builder ───────────────────────────────────

  Future<List<ChartItemRef>> getIndicatorGroups() =>
      _refList('/api/indicatorGroups.json', 'indicatorGroups');

  Future<List<ChartItemRef>> getIndicatorsInGroup(String groupId) =>
      _nestedRefList('/api/indicatorGroups/$groupId.json', 'indicators');

  Future<List<ChartItemRef>> getDataElementGroups() =>
      _refList('/api/dataElementGroups.json', 'dataElementGroups');

  /// Aggregatable data elements of one group, each with its COCs.
  Future<List<DataElementWithCocs>> getDataElementsInGroup(
      String groupId) async {
    final res = await _api
        .get('/api/dataElementGroups/$groupId.json', queryParameters: {
      'fields': 'dataElements[id,displayName,domainType,'
          'categoryCombo[categoryOptionCombos[id,displayName]]]',
    });
    final data = res.data as Map<String, dynamic>;
    final elements =
        (data['dataElements'] as List? ?? const []).cast<Map<String, dynamic>>();
    final result = <DataElementWithCocs>[
      for (final de in elements)
        if (de['domainType'] != 'TRACKER')
          DataElementWithCocs(
            ref: ChartItemRef(
              id: de['id'] as String,
              name: (de['displayName'] ?? '') as String,
            ),
            cocs: [
              for (final coc in ((de['categoryCombo']
                          as Map<String, dynamic>?)?['categoryOptionCombos']
                      as List? ??
                  const []))
                ChartItemRef(
                  id: (coc as Map)['id'] as String,
                  name: (coc['displayName'] ?? '') as String,
                ),
            ],
          ),
    ];
    result.sort((a, b) => a.ref.name.compareTo(b.ref.name));
    return result;
  }

  Future<List<ChartItemRef>> getDataSets() =>
      _refList('/api/dataSets.json', 'dataSets');

  Future<List<ChartItemRef>> _refList(String path, String key) async {
    final res = await _api.get(path, queryParameters: {
      'fields': 'id,displayName',
      'paging': 'false',
    });
    final items = ((res.data as Map<String, dynamic>)[key] as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final refs = [
      for (final i in items)
        ChartItemRef(id: i['id'] as String, name: (i['displayName'] ?? '') as String),
    ];
    refs.sort((a, b) => a.name.compareTo(b.name));
    return refs;
  }

  Future<List<ChartItemRef>> _nestedRefList(String path, String key) async {
    final res = await _api.get(path, queryParameters: {
      'fields': '$key[id,displayName]',
    });
    final items = ((res.data as Map<String, dynamic>)[key] as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final refs = [
      for (final i in items)
        ChartItemRef(id: i['id'] as String, name: (i['displayName'] ?? '') as String),
    ];
    refs.sort((a, b) => a.name.compareTo(b.name));
    return refs;
  }

  // ── Analytics ──────────────────────────────────────────────────

  /// dimension/filter parameter strings for a config — kept separate
  /// from the request so tests can assert the query shape.
  static ({List<String> dimensions, String filter}) analyticsParams(
          ChartConfig config) =>
      (
        dimensions: [
          'dx:${config.dxItems.join(';')}',
          'pe:${config.periodId}',
        ],
        filter: 'ou:${config.orgUnitId}',
      );

  /// Run one chart's analytics query and reshape the grid for the
  /// renderer: dx items are the series, periods the categories.
  Future<AnalyticsData> runChart(ChartConfig config) async {
    final params = analyticsParams(config);
    final res = await _api.get('/api/analytics.json', queryParameters: {
      'dimension': params.dimensions,
      'filter': params.filter,
      'includeMetadataDetails': 'false',
    });
    final grid = res.data as Map<String, dynamic>;

    final headers =
        (grid['headers'] as List? ?? const []).cast<Map<String, dynamic>>();
    final rows = (grid['rows'] as List? ?? const []).cast<List>();
    final metaData = grid['metaData'] as Map<String, dynamic>? ?? const {};
    final metaItems = metaData['items'] as Map<String, dynamic>? ?? const {};
    final dimOrder =
        metaData['dimensions'] as Map<String, dynamic>? ?? const {};

    // The user's own selection names beat metaData (operand ids like
    // de.coc are not always present there).
    final localNames = {for (final i in config.items) i.id: i.name};
    String nameOf(String id) =>
        (metaItems[id] as Map<String, dynamic>?)?['name'] as String? ??
        localNames[id] ??
        id;

    final headerIndex = {
      for (var i = 0; i < headers.length; i++) headers[i]['name'] as String: i,
    };
    final dxIndex = headerIndex['dx'];
    final peIndex = headerIndex['pe'];
    final valueIndex = headerIndex['value'];
    if (dxIndex == null || peIndex == null || valueIndex == null) {
      log.w('[charts] analytics grid for ${config.id} misses dx/pe/value');
      return AnalyticsData(
          visualizationId: config.id,
          title: config.name,
          type: config.chartType.dhis2Type,
          categories: const [],
          series: const []);
    }

    // Server order where provided; the request order otherwise.
    final dxOrder = (dimOrder['dx'] as List? ?? config.dxItems).cast<String>();
    final peOrder = (dimOrder['pe'] as List? ?? const []).cast<String>();
    final periods = peOrder.isNotEmpty
        ? peOrder
        : ({for (final r in rows) r[peIndex] as String}.toList()..sort());

    final cells = <String, double>{};
    for (final row in rows) {
      final v = double.tryParse(row[valueIndex].toString());
      if (v != null) cells['${row[dxIndex]}|${row[peIndex]}'] = v;
    }

    final result = AnalyticsData(
      visualizationId: config.id,
      title: config.name,
      type: config.chartType.dhis2Type,
      categories: [for (final pe in periods) nameOf(pe)],
      series: [
        for (final dx in dxOrder)
          AnalyticsSeries(
            name: nameOf(dx),
            values: [for (final pe in periods) cells['$dx|$pe']],
          ),
      ],
    );
    await _cacheResult(config.id, result);
    return result;
  }

  /// Online-first, cache-fallback load for the chart VIEW screen: runs
  /// the live query (caching it for next time) and only falls back to
  /// whatever was last cached for this chart if that fails — offline,
  /// timeout, server error. Rethrows the original error when there is
  /// no cache to fall back to; the UI then has nothing useful to show.
  ///
  /// [skipLiveAttempt] lets a caller that already knows it's offline
  /// (ConnectivityService) go straight to the cache instead of waiting
  /// out a ~30s connection timeout first.
  Future<ChartLoadResult> loadChart(
    ChartConfig config, {
    bool skipLiveAttempt = false,
  }) async {
    if (!skipLiveAttempt) {
      try {
        final data = await runChart(config);
        return ChartLoadResult(data: data, isFromCache: false);
      } catch (e) {
        final cached = await _readCache(config.id);
        if (cached == null) rethrow;
        log.w('[charts] live query failed for ${config.id} ($e) — '
            'showing cache from ${cached.cachedAt}');
        return ChartLoadResult(
            data: cached.data, isFromCache: true, cachedAt: cached.cachedAt);
      }
    }
    final cached = await _readCache(config.id);
    if (cached != null) {
      return ChartLoadResult(
          data: cached.data, isFromCache: true, cachedAt: cached.cachedAt);
    }
    throw const NetworkException(
        message: 'You are offline and no cached data is available for '
            'this chart yet.');
  }

  Future<void> _cacheResult(String chartId, AnalyticsData data) {
    return _db.setSyncInfo(
      _cacheKey(chartId),
      jsonEncode({
        'data': data.toJson(),
        'cachedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<({AnalyticsData data, DateTime cachedAt})?> _readCache(
      String chartId) async {
    final raw = await _db.getSyncInfo(_cacheKey(chartId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        data: AnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
        cachedAt: DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      log.e('[charts] cached result for $chartId unreadable: $e');
      return null;
    }
  }

  // ── Saved charts ───────────────────────────────────────────────

  Future<List<ChartConfig>> getSavedCharts() async {
    final raw = await _db.getSyncInfo(savedChartsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final charts = [for (final c in list) ChartConfig.fromJson(c)];
      charts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return charts;
    } catch (e) {
      log.e('[charts] saved charts unreadable, starting empty: $e');
      return const [];
    }
  }

  Future<void> saveChart(ChartConfig config) async {
    final charts = await getSavedCharts();
    final updated = [config, ...charts.where((c) => c.id != config.id)];
    await _writeAll(updated);
  }

  Future<void> deleteChart(String id) async {
    final charts = await getSavedCharts();
    await _writeAll([...charts.where((c) => c.id != id)]);
    await _db.setSyncInfo(_cacheKey(id), ''); // drop its cached result too
  }

  Future<void> _writeAll(List<ChartConfig> charts) => _db.setSyncInfo(
      savedChartsKey, jsonEncode([for (final c in charts) c.toJson()]));

  // ── Push to the server (DHIS2 Visualization object) ─────────────

  /// Every saved chart still pending or previously rejected gets
  /// pushed as a real DHIS2 Visualization — CREATE the first time
  /// (POST), then PUT to the same object on any later push (there is
  /// currently no chart-editing UI, so in practice this only ever
  /// creates). Safe to call repeatedly and offline: a transport
  /// failure leaves the chart pending for the next attempt, same
  /// pattern as data value/completeness push.
  Future<int> pushPendingCharts() async {
    final charts = await getSavedCharts();
    final pending = [
      for (final c in charts)
        if (c.syncState != ChartSyncState.synced) c,
    ];
    if (pending.isEmpty) return 0;

    var ok = 0;
    for (final chart in pending) {
      try {
        final payload = _visualizationPayload(chart);
        final res = chart.serverVisualizationId == null
            ? await _api.post('/api/visualizations.json', data: payload)
            : await _api.put(
                '/api/visualizations/${chart.serverVisualizationId}.json',
                data: payload);
        final response = (res.data as Map<String, dynamic>?)?['response']
            as Map<String, dynamic>?;
        final uid = chart.serverVisualizationId ?? response?['uid'] as String?;
        await _updateChart(chart.copyWith(
          syncState: ChartSyncState.synced,
          serverVisualizationId: uid,
          syncError: null,
        ));
        ok++;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        // 4xx with a body is a server VERDICT (validation rejected the
        // visualization) — retrying the identical payload can't
        // succeed, so settle as error the UI can surface. Anything
        // else (timeout, 5xx, no response) is transport trouble: leave
        // it pending for the next auto-sync pass.
        if (status != null &&
            status >= 400 &&
            status < 500 &&
            data is Map<String, dynamic>) {
          final why = _rejectionMessage(data);
          log.w('[charts] push rejected for ${chart.id}: $why');
          await _updateChart(
              chart.copyWith(syncState: ChartSyncState.error, syncError: why));
        } else {
          // Log the response body too, not just e.message — a 5xx
          // often carries the server's actual stack trace/exception
          // class in its body, which is the only way to tell "bad
          // payload we're sending" apart from "genuine server hiccup."
          log.e('[charts] push transport error for ${chart.id} '
              '(status: $status): ${e.message}\nresponse body: $data');
        }
      }
    }
    log.i('[charts] pushed $ok/${pending.length}');
    return ok;
  }

  /// One data dimension item, typed per the DHIS2 Visualization schema
  /// — confirmed against a live 2.40.1 server's own saved
  /// visualizations (`GET /api/visualizations.json?fields=...
  /// dataDimensionItems`): every reference is a NESTED object
  /// (`{dataElement:{id}}`, `{indicator:{id}}`,
  /// `{reportingRate:{dataSet:{id}, metric}}`), never the dotted
  /// composite id (`de.coc`, `dataSet.METRIC`) analytics uses for its
  /// `dx` dimension — that composite form only ever showed up inside
  /// `dimensionItem` (a server-computed display field), not in
  /// anything a client would write.
  Map<String, dynamic> _dataDimensionItem(ChartConfig config, ChartItemRef item) {
    switch (config.dataType) {
      case ChartDataType.indicator:
        return {
          'dataDimensionItemType': 'INDICATOR',
          'indicator': {'id': item.id},
        };
      case ChartDataType.dataElement:
        if (config.disaggregation == Disaggregation.detailsOnly) {
          // item.id is "deUid.cocUid" (see chart_builder_view.dart) —
          // split back into the two nested references. UNVERIFIED
          // against a live server (no operand example turned up in
          // the visualizations we fetched) — if this gets rejected,
          // the rejection message will show the real shape needed.
          final parts = item.id.split('.');
          return {
            'dataDimensionItemType': 'DATA_ELEMENT_OPERAND',
            'dataElementOperand': {
              'dataElement': {'id': parts[0]},
              'categoryOptionCombo': {
                'id': parts.length > 1 ? parts[1] : parts[0]
              },
            },
          };
        }
        return {
          'dataDimensionItemType': 'DATA_ELEMENT',
          'dataElement': {'id': item.id},
        };
      case ChartDataType.dataSet:
        return {
          'dataDimensionItemType': 'REPORTING_RATE',
          'reportingRate': {
            'dataSet': {'id': item.id},
            'metric': (config.metric ?? DataSetMetric.reportingRate).apiName,
          },
        };
    }
  }

  /// Plain metadata ids for the dx COLUMNS list — position-matched to
  /// [_dataDimensionItem]'s output (one id per `config.items` entry),
  /// per the same live-server evidence: the compact `columns[].items`
  /// list is always the plain dataElement/indicator/dataSet uid, even
  /// when the fuller `dataDimensionItems` entry at that position is an
  /// operand or a reporting-rate metric.
  List<String> _columnIds(ChartConfig config) {
    if (config.dataType == ChartDataType.dataElement &&
        config.disaggregation == Disaggregation.detailsOnly) {
      return [for (final item in config.items) item.id.split('.').first];
    }
    return [for (final item in config.items) item.id];
  }

  Map<String, dynamic> _visualizationPayload(ChartConfig config) {
    return {
      'name': config.name,
      'type': config.chartType.dhis2Type,
      'columns': [
        {
          'dimension': 'dx',
          'items': [for (final id in _columnIds(config)) {'id': id}],
        },
      ],
      'rows': [
        {
          'dimension': 'pe',
          'items': [
            {'id': config.periodId}
          ],
        },
      ],
      'filters': [
        {
          'dimension': 'ou',
          'items': [
            {'id': config.orgUnitId}
          ],
        },
      ],
      'dataDimensionItems': [
        for (final item in config.items) _dataDimensionItem(config, item),
      ],
    };
  }

  /// Same shape DHIS2 uses for object-endpoint validation errors:
  /// either an `errorReports`/`conflicts` list or a flat `message`.
  String _rejectionMessage(Map<String, dynamic> data) {
    final response = (data['response'] ?? data) as Map<String, dynamic>;
    final conflicts = (response['errorReports'] ?? response['conflicts'])
            as List? ??
        const [];
    if (conflicts.isNotEmpty) {
      return conflicts
          .map((c) => (c as Map)['message'] ?? c.toString())
          .join('; ');
    }
    return (data['message'] ?? 'Rejected by server').toString();
  }

  Future<void> _updateChart(ChartConfig updated) async {
    final charts = await getSavedCharts();
    await _writeAll([
      for (final c in charts) c.id == updated.id ? updated : c,
    ]);
  }
}

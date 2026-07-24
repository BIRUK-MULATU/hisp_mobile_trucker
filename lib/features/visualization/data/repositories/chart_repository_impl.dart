import 'dart:convert';

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

/// The chart builder's data side: metadata pickers straight from the
/// API (the feature is online-only — analytics has no offline mode),
/// the analytics query built from a ChartConfig, and the saved-chart
/// list persisted as JSON under one syncInfo key in the per-user
/// database (no schema change, so no migration).
class ChartRepositoryImpl {
  static const savedChartsKey = 'savedCharts';

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

    return AnalyticsData(
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
  }

  Future<void> _writeAll(List<ChartConfig> charts) => _db.setSyncInfo(
      savedChartsKey, jsonEncode([for (final c in charts) c.toJson()]));
}

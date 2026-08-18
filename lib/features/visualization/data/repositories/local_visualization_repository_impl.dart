import 'dart:convert';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../capture/domain/entities/org_unit_tree_node.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_config.dart';
import '../../domain/repositories/local_visualization_repository.dart';

/// Visualizations built and stored entirely on THIS device. Nothing
/// here ever creates or updates a DHIS2 Visualization object on the
/// server — only the DHIS2 Analytics API (read-only) is called, to
/// run a saved chart's query. The saved configuration lives as JSON
/// under one syncInfo key in the per-user local database (no schema
/// change, so no migration); every successful query result is cached
/// under its own key so a chart is still viewable offline.
class LocalVisualizationRepositoryImpl implements LocalVisualizationRepository {
  static const savedChartsKey = 'savedCharts';
  static String _cacheKey(String chartId) => 'chartCache_$chartId';

  final SessionService _session;
  final ApiClient? _apiOverride;

  LocalVisualizationRepositoryImpl({SessionService? session, ApiClient? api})
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

  @override
  Future<List<ChartItemRef>> getIndicatorGroups() =>
      _refList('/api/indicatorGroups.json', 'indicatorGroups');

  @override
  Future<List<ChartItemRef>> getIndicatorsInGroup(String groupId) =>
      _nestedRefList('/api/indicatorGroups/$groupId.json', 'indicators');

  @override
  Future<List<ChartItemRef>> getDataElementGroups() =>
      _refList('/api/dataElementGroups.json', 'dataElementGroups');

  @override
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

  @override
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

  /// Live org unit children for the builder's org unit picker —
  /// deliberately bypasses the local capture database entirely (never
  /// cached, never written locally): a chart can be built against ANY
  /// org unit in the full hierarchy, unlike Capture's own org unit
  /// tree, which is intentionally depth-bounded to root + direct
  /// children to keep offline storage small (see OrgUnitResource).
  /// The builder is already online-only end to end, so there's no
  /// offline case to support here.
  Future<List<OrgUnitTreeNode>> getOrgUnitChildrenLive(
      String parentId) async {
    final res = await _api.get('/api/organisationUnits.json', queryParameters: {
      'filter': 'parent.id:eq:$parentId',
      'fields': 'id,displayName,path,level,children[id]',
      'paging': 'false',
    });
    final items = ((res.data as Map<String, dynamic>)['organisationUnits']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final nodes = [
      for (final ou in items)
        OrgUnitTreeNode(
          id: ou['id'] as String,
          name: (ou['displayName'] ?? '') as String,
          parentId: parentId,
          level: ou['level'] as int? ?? 0,
          path: ou['path'] as String?,
          childCount: (ou['children'] as List? ?? const []).length,
        ),
    ];
    nodes.sort((a, b) => a.name.compareTo(b.name));
    return nodes;
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
  @override
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
    AnalyticsData result;
    if (dxIndex == null || peIndex == null || valueIndex == null) {
      log.w('[charts] analytics grid for ${config.id} misses dx/pe/value');
      result = AnalyticsData(
          visualizationId: config.id,
          title: config.name,
          type: config.chartType.dhis2Type,
          categories: const [],
          series: const []);
    } else {
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

      result = AnalyticsData(
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
    await _cacheResult(config.id, result);
    return result;
  }

  @override
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

  @override
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

  /// Creating and editing both go through here: a config sharing an
  /// existing id replaces it in place (editing), any other id is
  /// added as new — same list, same key, no separate "update" call.
  @override
  Future<void> saveChart(ChartConfig config) async {
    final charts = await getSavedCharts();
    final updated = [config, ...charts.where((c) => c.id != config.id)];
    await _writeAll(updated);
  }

  @override
  Future<void> deleteChart(String id) async {
    final charts = await getSavedCharts();
    await _writeAll([...charts.where((c) => c.id != id)]);
    await _db.setSyncInfo(_cacheKey(id), ''); // drop its cached result too
  }

  Future<void> _writeAll(List<ChartConfig> charts) => _db.setSyncInfo(
      savedChartsKey, jsonEncode([for (final c in charts) c.toJson()]));
}

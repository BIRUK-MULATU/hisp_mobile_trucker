import 'dart:convert';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_load_result.dart';
import '../../domain/entities/dashboard_ref.dart';
import '../../domain/entities/remote_visualization.dart';

/// The Server Dashboard side: browsing DHIS2 WebApp-authored
/// dashboards and their visualizations, entirely read-only. This app
/// never creates, edits, or pushes anything to these server objects —
/// see [LocalVisualizationRepositoryImpl] for the separate, purely
/// local charts built with Create New / Local Dashboard.
class ChartRepositoryImpl {
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

  // ── Server-side (WebApp) visualizations ─────────────────────────
  //
  // Read-only: nothing fetched here is ever written to the local
  // chart container or cached like [LocalVisualizationRepositoryImpl]
  // does for the user's own charts — these objects belong to the
  // server, not the device.

  /// Every visualization the current user can see on the server,
  /// newest concerns aside — just a flat, alphabetical reference list
  /// for the Charts screen to merge in alongside local charts.
  Future<List<RemoteVisualizationRef>> getServerVisualizations() async {
    final res = await _api.get('/api/visualizations.json', queryParameters: {
      'fields': 'id,name,type',
      'paging': 'false',
    });
    final items = ((res.data as Map<String, dynamic>)['visualizations']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final refs = [
      for (final i in items)
        RemoteVisualizationRef(
          id: i['id'] as String,
          name: (i['name'] ?? '') as String,
          type: (i['type'] ?? '') as String,
        ),
    ];
    refs.sort((a, b) => a.name.compareTo(b.name));
    return refs;
  }

  /// Runs a WebApp-authored visualization's OWN query, whatever its
  /// type — this app doesn't restrict which DHIS2 visualization types
  /// it will fetch or render. `columns`/`rows` are the dimensions that
  /// VARY in the result (each becomes part of the series/category
  /// key); `filters` are pinned and aggregated away, exactly as the
  /// DHIS2 Data Visualizer treats them. That distinction matters for
  /// correctness, not just chart type: e.g. a SINGLE_VALUE's `pe`
  /// filter (say LAST_12_MONTHS) should sum to one number, while a
  /// PIVOT_TABLE's `pe` on rows should stay broken out period by
  /// period — collapsing one into the other silently changes the
  /// numbers, not just the picture. Always attempts a live query; the
  /// result is cached (same store as this app's own charts, keyed by
  /// the visualization's id) purely so [loadServerVisualization] can
  /// fall back to it offline — the visualization's own DEFINITION is
  /// never cached or stored locally, only the last analytics answer.
  Future<AnalyticsData> runServerVisualization(
      RemoteVisualizationRef ref) async {
    final metaRes =
        await _api.get('/api/visualizations/${ref.id}.json', queryParameters: {
      'fields': 'id,name,type,'
          'columns[dimension,items[id,displayName]],'
          'rows[dimension,items[id,displayName]],'
          'filters[dimension,items[id,displayName]]',
    });
    final viz = metaRes.data as Map<String, dynamic>;
    final columnAxes =
        (viz['columns'] as List? ?? const []).cast<Map<String, dynamic>>();
    final rowAxes =
        (viz['rows'] as List? ?? const []).cast<Map<String, dynamic>>();
    final filterAxes =
        (viz['filters'] as List? ?? const []).cast<Map<String, dynamic>>();

    final dimensions = <String>[];
    final filters = <String>[];
    final localNames = <String, String>{};
    final columnDims = <String>[];
    final rowDims = <String>[];

    // One axis entry ({dimension, items}) → its query param + which
    // varying-dimension list (if any) it feeds; shared so columns and
    // rows are handled identically apart from which list they append
    // to, and names are collected from every axis the same way.
    void addAxis(Map<String, dynamic> axis, List<String>? varyingInto) {
      final dim = axis['dimension'] as String? ?? '';
      final items =
          (axis['items'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (dim.isEmpty || items.isEmpty) return;
      final ids = items.map((i) => i['id'] as String).join(';');
      for (final i in items) {
        localNames[i['id'] as String] = (i['displayName'] ?? '') as String;
      }
      if (varyingInto != null) {
        varyingInto.add(dim);
        dimensions.add('$dim:$ids');
      } else {
        filters.add('$dim:$ids');
      }
    }

    for (final axis in columnAxes) {
      addAxis(axis, columnDims);
    }
    for (final axis in rowAxes) {
      addAxis(axis, rowDims);
    }
    for (final axis in filterAxes) {
      addAxis(axis, null);
    }

    final gridRes = await _api.get('/api/analytics.json', queryParameters: {
      'dimension': dimensions,
      if (filters.isNotEmpty) 'filter': filters,
      'includeMetadataDetails': 'false',
    });

    final result = _reshapeGenericGrid(
      gridRes.data as Map<String, dynamic>,
      visualizationId: ref.id,
      title: (viz['name'] ?? ref.name) as String,
      type: (viz['type'] ?? ref.type) as String,
      localNames: localNames,
      columnDims: columnDims,
      rowDims: rowDims,
    );
    await _cacheResult(ref.id, result);
    return result;
  }

  /// Reshapes an analytics grid for a REMOTE visualization, which
  /// (unlike this app's own charts, always a plain dx-by-pe shape)
  /// may vary more than one dimension per axis — e.g. a pivot table
  /// with both org unit AND period on its rows. Every dimension on
  /// the COLUMNS axis becomes part of the series key; every one on
  /// ROWS becomes part of the category key, joined with " — " when
  /// there's more than one, so any combination still renders as one
  /// flat series×category grid instead of only supporting dx×pe. An
  /// axis with nothing on it collapses to a single implicit key
  /// (e.g. SINGLE_VALUE: dx on columns, nothing on rows).
  AnalyticsData _reshapeGenericGrid(
    Map<String, dynamic> grid, {
    required String visualizationId,
    required String title,
    required String type,
    required Map<String, String> localNames,
    required List<String> columnDims,
    required List<String> rowDims,
  }) {
    final headers =
        (grid['headers'] as List? ?? const []).cast<Map<String, dynamic>>();
    final rows = (grid['rows'] as List? ?? const []).cast<List>();
    final metaData = grid['metaData'] as Map<String, dynamic>? ?? const {};
    final metaItems = metaData['items'] as Map<String, dynamic>? ?? const {};

    String nameOf(String id) =>
        (metaItems[id] as Map<String, dynamic>?)?['name'] as String? ??
        localNames[id] ??
        id;

    final headerIndex = {
      for (var i = 0; i < headers.length; i++) headers[i]['name'] as String: i,
    };
    final valueIndex = headerIndex['value'];
    final colIndices =
        [for (final d in columnDims) headerIndex[d]].whereType<int>().toList();
    final rowIndices =
        [for (final d in rowDims) headerIndex[d]].whereType<int>().toList();
    if (valueIndex == null) {
      log.w('[charts] analytics grid for $visualizationId missing value column');
      return AnalyticsData(
          visualizationId: visualizationId,
          title: title,
          type: type,
          categories: const [],
          series: const []);
    }

    String keyOf(List row, List<int> idx) =>
        idx.isEmpty ? '' : idx.map((i) => row[i] as String).join('|');
    String labelOf(List row, List<int> idx) => idx.isEmpty
        ? title
        : idx.map((i) => nameOf(row[i] as String)).join(' — ');

    final seriesOrder = <String>[];
    final seriesLabels = <String, String>{};
    final categoryOrder = <String>[];
    final categoryLabels = <String, String>{};
    final cells = <String, double>{};

    for (final row in rows) {
      final v = double.tryParse(row[valueIndex].toString());
      if (v == null) continue;
      final sKey = keyOf(row, colIndices);
      final cKey = keyOf(row, rowIndices);
      if (!seriesLabels.containsKey(sKey)) {
        seriesLabels[sKey] = labelOf(row, colIndices);
        seriesOrder.add(sKey);
      }
      if (!categoryLabels.containsKey(cKey)) {
        categoryLabels[cKey] = labelOf(row, rowIndices);
        categoryOrder.add(cKey);
      }
      cells['$sKey|$cKey'] = v;
    }

    return AnalyticsData(
      visualizationId: visualizationId,
      title: title,
      type: type,
      categories: [for (final c in categoryOrder) categoryLabels[c]!],
      series: [
        for (final s in seriesOrder)
          AnalyticsSeries(
            name: seriesLabels[s]!,
            values: [for (final c in categoryOrder) cells['$s|$c']],
          ),
      ],
    );
  }

  // ── Dashboards (grouping for server visualizations) ─────────────
  //
  // Mirrors the WebApp's Dashboard app: a dashboard is a named group
  // of visualization items. The app never creates or edits one — but
  // every level (the dashboard list, one dashboard's item list, and
  // each item's analytics result) caches its last successful fetch
  // under syncInfo, the same read-only "last known answer" pattern
  // used for this app's own saved charts, so the whole Dashboards tab
  // still works offline.

  static const _dashboardsListKey = 'dashboardsList';
  static String _dashboardItemsCacheKey(String dashboardId) =>
      'dashboardItems_$dashboardId';

  Future<List<DashboardRef>> getDashboards() async {
    final res = await _api.get('/api/dashboards.json', queryParameters: {
      'fields': 'id,name',
      'paging': 'false',
    });
    final items = ((res.data as Map<String, dynamic>)['dashboards'] as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final refs = [
      for (final i in items)
        DashboardRef(id: i['id'] as String, name: (i['name'] ?? '') as String),
    ];
    // Case-insensitive: plain compareTo is ordinal, so every ALL-CAPS
    // name (e.g. "ART retension") would sort before any mixed-case
    // one (e.g. "Adolescent...") regardless of actual letter order.
    refs.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _db.setSyncInfo(
        _dashboardsListKey, jsonEncode([for (final r in refs) r.toJson()]));
    return refs;
  }

  /// The visualization items under one dashboard, in the WebApp's
  /// order. MAP and APP dashboard items are skipped — this app only
  /// renders analytics visualizations (see [Dhis2Chart]).
  Future<List<RemoteVisualizationRef>> getDashboardVisualizations(
      String dashboardId) async {
    final res = await _api
        .get('/api/dashboards/$dashboardId.json', queryParameters: {
      'fields': 'dashboardItems[type,visualization[id,name,type]]',
    });
    final dashboardItems = ((res.data as Map<String, dynamic>)['dashboardItems']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final refs = [
      for (final item in dashboardItems)
        if (item['type'] == 'VISUALIZATION' && item['visualization'] != null)
          RemoteVisualizationRef(
            id: (item['visualization'] as Map)['id'] as String,
            name: ((item['visualization'] as Map)['name'] ?? '') as String,
            type: ((item['visualization'] as Map)['type'] ?? '') as String,
          ),
    ];
    await _db.setSyncInfo(_dashboardItemsCacheKey(dashboardId),
        jsonEncode([for (final r in refs) r.toJson()]));
    return refs;
  }

  /// Online-first, cache-fallback dashboard list — same shape as
  /// [loadServerVisualization]: try live, fall back to the last
  /// successful fetch when offline or the request fails.
  Future<({List<DashboardRef> dashboards, bool isFromCache})> loadDashboards({
    bool skipLiveAttempt = false,
  }) async {
    if (!skipLiveAttempt) {
      try {
        final dashboards = await getDashboards();
        return (dashboards: dashboards, isFromCache: false);
      } catch (e) {
        final cached = await _readDashboardsCache();
        if (cached == null) rethrow;
        log.w('[charts] live dashboards fetch failed ($e) — using cache');
        return (dashboards: cached, isFromCache: true);
      }
    }
    final cached = await _readDashboardsCache();
    if (cached != null) return (dashboards: cached, isFromCache: true);
    throw const NetworkException(
        message:
            'You are offline and no cached dashboards are available yet.');
  }

  Future<List<DashboardRef>?> _readDashboardsCache() async {
    final raw = await _db.getSyncInfo(_dashboardsListKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return [for (final d in list) DashboardRef.fromJson(d)];
    } catch (e) {
      log.e('[charts] cached dashboards unreadable: $e');
      return null;
    }
  }

  /// Online-first, cache-fallback item list for one dashboard.
  Future<({List<RemoteVisualizationRef> items, bool isFromCache})>
      loadDashboardVisualizations(
    String dashboardId, {
    bool skipLiveAttempt = false,
  }) async {
    if (!skipLiveAttempt) {
      try {
        final items = await getDashboardVisualizations(dashboardId);
        return (items: items, isFromCache: false);
      } catch (e) {
        final cached = await _readDashboardItemsCache(dashboardId);
        if (cached == null) rethrow;
        log.w('[charts] live dashboard items fetch failed for '
            '$dashboardId ($e) — using cache');
        return (items: cached, isFromCache: true);
      }
    }
    final cached = await _readDashboardItemsCache(dashboardId);
    if (cached != null) return (items: cached, isFromCache: true);
    throw const NetworkException(
        message:
            'You are offline and this dashboard has no cached items yet.');
  }

  Future<List<RemoteVisualizationRef>?> _readDashboardItemsCache(
      String dashboardId) async {
    final raw = await _db.getSyncInfo(_dashboardItemsCacheKey(dashboardId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return [for (final i in list) RemoteVisualizationRef.fromJson(i)];
    } catch (e) {
      log.e('[charts] cached dashboard items for $dashboardId unreadable: $e');
      return null;
    }
  }

  /// Online-first, cache-fallback load for one dashboard item's chart
  /// — reuses [_cacheResult]/[_readCache] keyed by the visualization's
  /// own id. Safe to share that cache namespace with this app's local
  /// chart ids: local ids are `DateTime.millisecondsSinceEpoch`
  /// strings (pure digits), DHIS2 uids are always 11 chars starting
  /// with a letter — the two id spaces can never collide.
  Future<ChartLoadResult> loadServerVisualization(
    RemoteVisualizationRef ref, {
    bool skipLiveAttempt = false,
  }) async {
    if (!skipLiveAttempt) {
      try {
        final data = await runServerVisualization(ref);
        return ChartLoadResult(data: data, isFromCache: false);
      } catch (e) {
        final cached = await _readCache(ref.id);
        if (cached == null) rethrow;
        log.w('[charts] live query failed for ${ref.id} ($e) — '
            'showing cache from ${cached.cachedAt}');
        return ChartLoadResult(
            data: cached.data, isFromCache: true, cachedAt: cached.cachedAt);
      }
    }
    final cached = await _readCache(ref.id);
    if (cached != null) {
      return ChartLoadResult(
          data: cached.data, isFromCache: true, cachedAt: cached.cachedAt);
    }
    throw const NetworkException(
        message: 'You are offline and no cached data is available for '
            'this visualization yet.');
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
}

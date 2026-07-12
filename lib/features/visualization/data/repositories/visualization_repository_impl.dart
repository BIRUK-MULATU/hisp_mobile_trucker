import '../../../../core/auth/app_session.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/dashboard_entity.dart';

/// Dashboards and charts straight from the DHIS2 analytics stack:
/// /api/dashboards for the list, /api/visualizations/{id} for each
/// chart's definition, /api/analytics for the numbers — the same
/// pipeline the DHIS2 web app uses. Online-only for now: caching
/// analytics locally needs new tables, which is blocked on the
/// migration strategy (schemaVersion is still 1).
class VisualizationRepositoryImpl {
  ApiClient get _api {
    final api = AppSession.instance.api;
    if (api == null) {
      throw const NetworkException(
          message: 'Visualizations need a connection to the server.');
    }
    return api;
  }

  /// The user's dashboards with their renderable visualization items.
  Future<List<DashboardEntity>> getDashboards() async {
    final res = await _api.get('/api/dashboards.json', queryParameters: {
      'fields': 'id,displayName,dashboardItems[type,'
          'visualization[id,displayName,type]]',
      'paging': 'false',
    });
    final data = res.data as Map<String, dynamic>;
    final dashboards = (data['dashboards'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    return [
      for (final d in dashboards)
        () {
          final items = (d['dashboardItems'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          final visualizations = <DashboardVisualizationRef>[];
          var unsupported = 0;
          for (final item in items) {
            final viz = item['visualization'] as Map<String, dynamic>?;
            if (item['type'] == 'VISUALIZATION' && viz != null) {
              visualizations.add(DashboardVisualizationRef(
                id: viz['id'] as String,
                name: (viz['displayName'] ?? '') as String,
                type: (viz['type'] ?? 'PIVOT_TABLE') as String,
              ));
            } else {
              unsupported++;
            }
          }
          return DashboardEntity(
            id: d['id'] as String,
            name: (d['displayName'] ?? '') as String,
            visualizations: visualizations,
            unsupportedItems: unsupported,
          );
        }(),
    ];
  }

  /// Fetch one visualization's definition, run its analytics query,
  /// and reshape the row list into chartable series × categories.
  Future<AnalyticsData> getVisualizationData(
      DashboardVisualizationRef ref) async {
    final vizRes =
        await _api.get('/api/visualizations/${ref.id}.json', queryParameters: {
      'fields': 'id,displayName,type,'
          'columns[dimension,items[id]],'
          'rows[dimension,items[id]],'
          'filters[dimension,items[id]],'
          'relativePeriods',
    });
    final viz = vizRes.data as Map<String, dynamic>;

    final relativePeriods = _activeRelativePeriods(
        viz['relativePeriods'] as Map<String, dynamic>?);
    final columns =
        _dimensionParams(viz['columns'] as List?, relativePeriods);
    final rows = _dimensionParams(viz['rows'] as List?, relativePeriods);
    final filters =
        _dimensionParams(viz['filters'] as List?, relativePeriods);

    final res = await _api.get('/api/analytics.json', queryParameters: {
      'dimension': [...columns, ...rows],
      if (filters.isNotEmpty) 'filter': filters,
      'includeMetadataDetails': 'false',
    });
    final grid = res.data as Map<String, dynamic>;

    return _reshape(
      grid,
      ref: ref,
      title: (viz['displayName'] ?? ref.name) as String,
      type: (viz['type'] ?? ref.type) as String,
      seriesDims: _dimensionNames(viz['columns'] as List?),
      categoryDims: _dimensionNames(viz['rows'] as List?),
    );
  }

  // ── Query building ─────────────────────────────────────────────

  List<String> _dimensionNames(List? dims) => [
        for (final d in (dims ?? const []).cast<Map<String, dynamic>>())
          d['dimension'] as String,
      ];

  /// `dim:item;item` parameter strings for columns/rows/filters.
  List<String> _dimensionParams(List? dims, List<String> relativePeriods) {
    final params = <String>[];
    for (final d in (dims ?? const []).cast<Map<String, dynamic>>()) {
      final dim = d['dimension'] as String;
      final items = [
        for (final i
            in (d['items'] as List? ?? const []).cast<Map<String, dynamic>>())
          i['id'] as String,
      ];
      // The pe dimension often carries no fixed items — its periods
      // live in the relativePeriods flags instead.
      if (dim == 'pe' && items.isEmpty) items.addAll(relativePeriods);
      // An empty ou dimension means "the user's own org unit".
      if (dim == 'ou' && items.isEmpty) items.add('USER_ORGUNIT');
      if (items.isEmpty) continue;
      params.add('$dim:${items.join(';')}');
    }
    return params;
  }

  /// relativePeriods flags -> analytics ids: the JSON keys are the
  /// camelCase of the id (last12Months -> LAST_12_MONTHS), so the
  /// translation is mechanical.
  List<String> _activeRelativePeriods(Map<String, dynamic>? flags) => [
        if (flags != null)
          for (final e in flags.entries)
            if (e.value == true) _camelToUpperSnake(e.key),
      ];

  static String _camelToUpperSnake(String s) => s
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z0-9])'), (m) => '${m[1]}_${m[2]}')
      .replaceAllMapped(
          RegExp(r'([0-9])([A-Za-z])'), (m) => '${m[1]}_${m[2]}')
      .toUpperCase();

  // ── Response reshaping ─────────────────────────────────────────

  AnalyticsData _reshape(
    Map<String, dynamic> grid, {
    required DashboardVisualizationRef ref,
    required String title,
    required String type,
    required List<String> seriesDims,
    required List<String> categoryDims,
  }) {
    final headers =
        (grid['headers'] as List? ?? const []).cast<Map<String, dynamic>>();
    final rows = (grid['rows'] as List? ?? const []).cast<List>();
    final metaData = grid['metaData'] as Map<String, dynamic>? ?? const {};
    final items = metaData['items'] as Map<String, dynamic>? ?? const {};
    final dimOrder =
        metaData['dimensions'] as Map<String, dynamic>? ?? const {};

    String nameOf(String id) =>
        (items[id] as Map<String, dynamic>?)?['name'] as String? ?? id;

    final headerIndex = {
      for (var i = 0; i < headers.length; i++) headers[i]['name'] as String: i,
    };
    final valueIndex = headerIndex['value'];
    if (valueIndex == null) {
      log.w('[viz] analytics grid for ${ref.id} has no value column');
      return AnalyticsData(
          visualizationId: ref.id,
          title: title,
          type: type,
          categories: const [],
          series: const []);
    }

    // Composite key per axis: the ids of all its dimensions joined.
    // Server-provided dimension order keeps categories/series stable.
    List<String> axisKeys(List<String> dims) {
      final perDim = [
        for (final d in dims)
          [...(dimOrder[d] as List? ?? const []).cast<String>()],
      ];
      var combos = <List<String>>[[]];
      for (final ids in perDim) {
        combos = [
          for (final c in combos)
            for (final id in ids) [...c, id],
        ];
      }
      return [for (final c in combos) c.join('|')];
    }

    String rowKey(List row, List<String> dims) =>
        [for (final d in dims) row[headerIndex[d] ?? 0] as String].join('|');

    String keyName(String key) =>
        key.split('|').map(nameOf).join(' · ');

    // No explicit rows dimension (e.g. single value): one category.
    final categoryKeys =
        categoryDims.isEmpty ? [''] : axisKeys(categoryDims);
    final seriesKeys = seriesDims.isEmpty ? [''] : axisKeys(seriesDims);

    final cells = <String, double>{};
    for (final row in rows) {
      final sk = seriesDims.isEmpty ? '' : rowKey(row, seriesDims);
      final ck = categoryDims.isEmpty ? '' : rowKey(row, categoryDims);
      final v = double.tryParse(row[valueIndex].toString());
      if (v != null) cells['$sk||$ck'] = v;
    }

    return AnalyticsData(
      visualizationId: ref.id,
      title: title,
      type: type,
      categories: [for (final ck in categoryKeys) keyName(ck)],
      series: [
        for (final sk in seriesKeys)
          AnalyticsSeries(
            name: keyName(sk),
            values: [for (final ck in categoryKeys) cells['$sk||$ck']],
          ),
      ],
    );
  }
}

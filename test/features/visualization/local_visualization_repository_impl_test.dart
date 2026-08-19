import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/errors/exceptions.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';
import 'package:hisp_mobile_trucker/features/visualization/data/repositories/local_visualization_repository_impl.dart';
import 'package:hisp_mobile_trucker/features/visualization/domain/entities/chart_config.dart';

/// A session whose database is the test's in-memory one — no login.
class _TestSession extends SessionService {
  _TestSession(this._testDb);
  final AppDatabase _testDb;

  @override
  AppDatabase get db => _testDb;
}

/// Replays one canned analytics response and records the request uri.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({required this.body});

  final Map<String, dynamic> body;
  Uri? lastUri;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? _, Future<void>? __) async {
    lastUri = options.uri;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Every request fails as if the server were unreachable.
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? _, Future<void>? __) async {
    throw DioException(
        requestOptions: options, type: DioExceptionType.connectionError);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  ChartConfig config({
    ChartDataType dataType = ChartDataType.indicator,
    List<ChartItemRef> items = const [
      ChartItemRef(id: 'indicator01', name: 'ANC 1st visit')
    ],
    DataSetMetric? metric,
    String id = 'chart1',
  }) =>
      ChartConfig(
        id: id,
        name: 'Test chart',
        chartType: ChartType.column,
        dataType: dataType,
        items: items,
        metric: metric,
        orgUnitId: 'orgUnit0001',
        orgUnitName: 'FMOH',
        periodKind: PeriodKind.relative,
        periodId: 'LAST_3_MONTHS',
        periodLabel: 'Last 3 Months',
        createdAt: DateTime(2026, 7, 24),
      );

  group('ChartConfig JSON', () {
    test('round-trips through toJson/fromJson', () {
      final original = ChartConfig(
        id: 'c1',
        name: 'My chart',
        chartType: ChartType.gauge,
        dataType: ChartDataType.dataElement,
        groupId: 'deGroup01',
        groupName: 'RMNCH',
        items: const [
          ChartItemRef(id: 'de001.coc01', name: 'ANC visits <15'),
        ],
        disaggregation: Disaggregation.detailsOnly,
        orgUnitId: 'ou1',
        orgUnitName: 'Facility A',
        periodKind: PeriodKind.fixed,
        periodId: '201811',
        periodLabel: 'This Month · Hamle 2018',
        createdAt: DateTime(2026, 7, 24, 10, 30),
      );

      final restored = ChartConfig.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.chartType, ChartType.gauge);
      expect(restored.dataType, ChartDataType.dataElement);
      expect(restored.groupId, 'deGroup01');
      expect(restored.groupName, 'RMNCH');
      expect(restored.items.single.id, 'de001.coc01');
      expect(restored.disaggregation, Disaggregation.detailsOnly);
      expect(restored.periodKind, PeriodKind.fixed);
      expect(restored.periodId, '201811');
      expect(restored.createdAt, original.createdAt);
    });

    test('dataset dx items carry the metric suffix', () {
      final c = config(
        dataType: ChartDataType.dataSet,
        items: const [ChartItemRef(id: 'dataSet0001', name: 'HMIS Monthly')],
        metric: DataSetMetric.reportingRate,
      );
      expect(c.dxItems, ['dataSet0001.REPORTING_RATE']);
    });
  });

  group('saved charts', () {
    test('save, list newest-first, delete', () async {
      final repo = LocalVisualizationRepositoryImpl(session: _TestSession(db));

      await repo.saveChart(config(id: 'a'));
      await repo.saveChart(config(id: 'b'));

      var charts = await repo.getSavedCharts();
      expect([for (final c in charts) c.id], ['b', 'a']);

      await repo.deleteChart('b');
      charts = await repo.getSavedCharts();
      expect([for (final c in charts) c.id], ['a']);
    });

    test(
        'saving a config with an existing id overwrites it in place '
        '(this is how editing persists)', () async {
      final repo = LocalVisualizationRepositoryImpl(session: _TestSession(db));
      await repo.saveChart(config(id: 'a'));

      final edited = ChartConfig(
        id: 'a',
        name: 'Renamed chart',
        chartType: ChartType.pie,
        dataType: ChartDataType.indicator,
        items: const [ChartItemRef(id: 'indicator02', name: 'Edited item')],
        orgUnitId: 'orgUnit0002',
        orgUnitName: 'A different facility',
        periodKind: PeriodKind.relative,
        periodId: 'THIS_YEAR',
        periodLabel: 'This Year',
        createdAt: DateTime(2026, 7, 24), // original createdAt preserved
      );
      await repo.saveChart(edited);

      final charts = await repo.getSavedCharts();
      expect(charts, hasLength(1));
      expect(charts.single.name, 'Renamed chart');
      expect(charts.single.chartType, ChartType.pie);
      expect(charts.single.items.single.id, 'indicator02');
    });

    test('unreadable stored JSON degrades to an empty list', () async {
      await db.setSyncInfo(
          LocalVisualizationRepositoryImpl.savedChartsKey, 'not json');
      final repo = LocalVisualizationRepositoryImpl(session: _TestSession(db));
      expect(await repo.getSavedCharts(), isEmpty);
    });
  });

  group('analytics', () {
    test('query parameters put dx+pe in dimensions and ou in filter', () {
      final params = LocalVisualizationRepositoryImpl.analyticsParams(config(
        items: const [
          ChartItemRef(id: 'ind01', name: 'A'),
          ChartItemRef(id: 'ind02', name: 'B'),
        ],
      ));
      expect(params.dimensions, ['dx:ind01;ind02', 'pe:LAST_3_MONTHS']);
      expect(params.filter, 'ou:orgUnit0001');
    });

    test('reshapes the grid: dx series × pe categories, server order',
        () async {
      final adapter = _CannedAdapter(body: {
        'headers': [
          {'name': 'dx'},
          {'name': 'pe'},
          {'name': 'value'},
        ],
        'metaData': {
          'items': {
            'indicator01': {'name': 'ANC 1st visit'},
            '201810': {'name': 'Sene 2018'},
            '201811': {'name': 'Hamle 2018'},
          },
          'dimensions': {
            'dx': ['indicator01'],
            'pe': ['201810', '201811'],
          },
        },
        'rows': [
          ['indicator01', '201811', '25.0'],
          ['indicator01', '201810', '20.0'],
        ],
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;

      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);
      final data = await repo.runChart(config());

      expect(adapter.lastUri!.path, '/api/analytics.json');
      expect(data.categories, ['Sene 2018', 'Hamle 2018']);
      expect(data.series.single.name, 'ANC 1st visit');
      expect(data.series.single.values, [20.0, 25.0]);
      expect(data.type, 'COLUMN');
    });

    Map<String, dynamic> cannedBody() => {
          'headers': [
            {'name': 'dx'},
            {'name': 'pe'},
            {'name': 'value'},
          ],
          'metaData': {
            'items': {
              'indicator01': {'name': 'ANC 1st visit'},
              '201811': {'name': 'Hamle 2018'},
            },
            'dimensions': {
              'dx': ['indicator01'],
              'pe': ['201811'],
            },
          },
          'rows': [
            ['indicator01', '201811', '25.0'],
          ],
        };

    test('runChart caches its result for later offline viewing', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      await repo.runChart(config());

      // A later live attempt that fails falls back to what was cached.
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final result = await repo.loadChart(config());
      expect(result.isFromCache, isTrue);
      expect(result.cachedAt, isNotNull);
      expect(result.data.series.single.values, [25.0]);
    });

    test('loadChart with skipLiveAttempt reads the cache directly', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);
      await repo.runChart(config());

      final result = await repo.loadChart(config(), skipLiveAttempt: true);
      expect(result.isFromCache, isTrue);
      expect(result.data.categories, ['Hamle 2018']);
    });

    test('loadChart throws when offline and nothing is cached yet', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      expect(
        () => repo.loadChart(config(), skipLiveAttempt: true),
        throwsA(isA<NetworkException>()),
      );
    });

    test('deleteChart also clears its cached result', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);
      await repo.saveChart(config());
      await repo.runChart(config());

      await repo.deleteChart('chart1');

      expect(
        () => repo.loadChart(config(), skipLiveAttempt: true),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getOrgUnitChildrenLive', () {
    test(
        'queries the server directly, filtered to the parent, not the '
        'local (depth-bounded) capture tree', () async {
      final adapter = _CannedAdapter(body: {
        'organisationUnits': [
          {
            'id': 'healthCenter1',
            'displayName': 'Health Center B',
            'path': '/national/region/zone/woreda/phcuA/healthCenter1',
            'level': 6,
            'children': [
              {'id': 'healthPost1'},
              {'id': 'healthPost2'},
            ],
          },
          {
            'id': 'healthCenter2',
            'displayName': 'Health Center A',
            'path': '/national/region/zone/woreda/phcuA/healthCenter2',
            'level': 6,
            'children': <Map<String, dynamic>>[],
          },
        ],
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      final children = await repo.getOrgUnitChildrenLive('phcuA');

      expect(adapter.lastUri!.path, '/api/organisationUnits.json');
      expect(adapter.lastUri!.queryParameters['filter'], 'parent.id:eq:phcuA');
      // Alphabetical, and childCount derived from the nested children.
      expect(
          children.map((c) => c.name), ['Health Center A', 'Health Center B']);
      expect(children.firstWhere((c) => c.id == 'healthCenter1').childCount, 2);
      expect(children.firstWhere((c) => c.id == 'healthCenter2').childCount, 0);
      expect(children.first.parentId, 'phcuA');
    });
  });

  group('offline pickers fall back to locally synced metadata', () {
    test(
        'getAllIndicatorsLocal reads straight from the synced table — no '
        'live call at all (indicator groups aren\'t synced, so this is '
        'the offline substitute)', () async {
      await db.into(db.indicatorsTable).insert(IndicatorsTableCompanion.insert(
            uid: 'indicator01',
            name: 'ANC 1st visit',
            displayName: 'ANC 1st visit',
            numerator: '#{de1}',
            denominator: '1',
          ));
      final repo = LocalVisualizationRepositoryImpl(session: _TestSession(db));

      final indicators = await repo.getAllIndicatorsLocal();

      expect(indicators.single.id, 'indicator01');
      expect(indicators.single.name, 'ANC 1st visit');
    });

    test(
        'getIndicatorGroups/getIndicatorsInGroup stay online-only — no '
        'local table backs them', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      expect(() => repo.getIndicatorGroups(), throwsA(isA<DioException>()));
      expect(() => repo.getIndicatorsInGroup('grp1'),
          throwsA(isA<DioException>()));
    });

    test(
        'getDataElementGroups falls back to the locally synced groups '
        'when the live call fails', () async {
      await db.into(db.dataElementGroupsTable).insert(
            DataElementGroupsTableCompanion.insert(
                uid: 'deGroup0001', name: 'RMNCH', displayName: 'RMNCH'),
          );
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      final groups = await repo.getDataElementGroups();

      expect(groups.single.id, 'deGroup0001');
      expect(groups.single.name, 'RMNCH');
    });

    test(
        'getDataElementsInGroup falls back to the local group membership '
        'and expands each element\'s category option combos', () async {
      await db.into(db.categoryOptionCombosTable).insert(
            CategoryOptionCombosTableCompanion.insert(
                uid: 'catOptCoc01',
                name: 'Female',
                categoryComboUid: 'catCombo001'),
          );
      await db.into(db.dataElementsTable).insert(
            DataElementsTableCompanion.insert(
              uid: 'dataElem001',
              name: 'ANC visits',
              displayName: 'ANC visits',
              formName: 'ANC visits',
              valueType: 'NUMBER',
              categoryComboUid: 'catCombo001',
            ),
          );
      await db.into(db.dataElementGroupsTable).insert(
            DataElementGroupsTableCompanion.insert(
                uid: 'deGroup0001', name: 'RMNCH', displayName: 'RMNCH'),
          );
      await db.into(db.dataElementGroupMembersTable).insert(
            DataElementGroupMembersTableCompanion.insert(
                dataElementGroupUid: 'deGroup0001',
                dataElementUid: 'dataElem001'),
          );
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      final elements = await repo.getDataElementsInGroup('deGroup0001');

      expect(elements.single.ref.id, 'dataElem001');
      expect(elements.single.cocs.single.id, 'catOptCoc01');
      expect(elements.single.cocs.single.name, 'Female');
    });

    test(
        'getDataSets falls back to the locally synced data sets when the '
        'live call fails', () async {
      await db.into(db.dataSetsTable).insert(
            DataSetsTableCompanion.insert(
              uid: 'dataSet0001',
              name: 'HMIS Monthly',
              displayName: 'HMIS Monthly',
              periodType: 'Monthly',
              categoryComboUid: 'catCombo001',
            ),
          );
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      final sets = await repo.getDataSets();

      expect(sets.single.id, 'dataSet0001');
      expect(sets.single.name, 'HMIS Monthly');
    });

    test(
        'getDataElementGroups still throws when nothing is synced locally '
        'either', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);

      expect(() => repo.getDataElementGroups(), throwsA(isA<DioException>()));
    });
  });

  group('draft charts', () {
    Map<String, dynamic> cannedBody() => {
          'headers': [
            {'name': 'dx'},
            {'name': 'pe'},
            {'name': 'value'},
          ],
          'metaData': {
            'items': {
              'indicator01': {'name': 'ANC 1st visit'},
              '201811': {'name': 'Hamle 2018'},
            },
            'dimensions': {
              'dx': ['indicator01'],
              'pe': ['201811'],
            },
          },
          'rows': [
            ['indicator01', '201811', '25.0'],
          ],
        };

    test(
        'promotePendingDrafts runs the query and clears isDraft once '
        'online', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);
      await repo.saveChart(config().copyWith(isDraft: true));

      // Still offline: nothing to promote.
      expect(await repo.promotePendingDrafts(), 0);
      expect((await repo.getSavedCharts()).single.isDraft, isTrue);

      // Back online: the draft's query succeeds, so it graduates.
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      expect(await repo.promotePendingDrafts(), 1);
      final promoted = (await repo.getSavedCharts()).single;
      expect(promoted.isDraft, isFalse);

      // Its result is cached too, same as any other successful run.
      final result = await repo.loadChart(promoted, skipLiveAttempt: true);
      expect(result.data.series.single.values, [25.0]);
    });

    test('promotePendingDrafts leaves non-draft charts untouched', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo = LocalVisualizationRepositoryImpl(
          session: _TestSession(db), api: client);
      await repo.saveChart(config()); // isDraft: false by default

      expect(await repo.promotePendingDrafts(), 0);
    });
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/errors/exceptions.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';
import 'package:hisp_mobile_trucker/features/visualization/data/repositories/chart_repository_impl.dart';
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
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
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
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
    throw DioException(
        requestOptions: options, type: DioExceptionType.connectionError);
  }

  @override
  void close({bool force = false}) {}
}

/// Returns one canned status/body for every request and records the
/// last request's method, path and body for assertions.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
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
      final repo = ChartRepositoryImpl(session: _TestSession(db));

      await repo.saveChart(config(id: 'a'));
      await repo.saveChart(config(id: 'b'));

      var charts = await repo.getSavedCharts();
      expect([for (final c in charts) c.id], ['b', 'a']);

      await repo.deleteChart('b');
      charts = await repo.getSavedCharts();
      expect([for (final c in charts) c.id], ['a']);
    });

    test('unreadable stored JSON degrades to an empty list', () async {
      await db.setSyncInfo(ChartRepositoryImpl.savedChartsKey, 'not json');
      final repo = ChartRepositoryImpl(session: _TestSession(db));
      expect(await repo.getSavedCharts(), isEmpty);
    });
  });

  group('analytics', () {
    test('query parameters put dx+pe in dimensions and ou in filter', () {
      final params = ChartRepositoryImpl.analyticsParams(config(
        items: const [
          ChartItemRef(id: 'ind01', name: 'A'),
          ChartItemRef(id: 'ind02', name: 'B'),
        ],
      ));
      expect(params.dimensions,
          ['dx:ind01;ind02', 'pe:LAST_3_MONTHS']);
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

      final repo =
          ChartRepositoryImpl(session: _TestSession(db), api: client);
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
      final repo =
          ChartRepositoryImpl(session: _TestSession(db), api: client);

      await repo.runChart(config());

      // A later live attempt that fails falls back to what was cached.
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final result = await repo.loadChart(config());
      expect(result.isFromCache, isTrue);
      expect(result.cachedAt, isNotNull);
      expect(result.data.series.single.values, [25.0]);
    });

    test('loadChart with skipLiveAttempt reads the cache directly',
        () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo =
          ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.runChart(config());

      final result =
          await repo.loadChart(config(), skipLiveAttempt: true);
      expect(result.isFromCache, isTrue);
      expect(result.data.categories, ['Hamle 2018']);
    });

    test('loadChart throws when offline and nothing is cached yet',
        () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo =
          ChartRepositoryImpl(session: _TestSession(db), api: client);

      expect(
        () => repo.loadChart(config(), skipLiveAttempt: true),
        throwsA(isA<NetworkException>()),
      );
    });

    test('deleteChart also clears its cached result', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _CannedAdapter(body: cannedBody());
      final repo =
          ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config());
      await repo.runChart(config());

      await repo.deleteChart('chart1');

      expect(
        () => repo.loadChart(config(), skipLiveAttempt: true),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('push to server', () {
    test('creates a new Visualization and stores the server uid', () async {
      final adapter = _RecordingAdapter(statusCode: 201, body: {
        'httpStatus': 'Created',
        'response': {'uid': 'viz00000001'},
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config());

      final pushed = await repo.pushPendingCharts();

      expect(pushed, 1);
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.path, '/api/visualizations.json');
      final saved = (await repo.getSavedCharts()).single;
      expect(saved.syncState, ChartSyncState.synced);
      expect(saved.serverVisualizationId, 'viz00000001');
    });

    test('already-synced charts are not pushed again', () async {
      final adapter = _ThrowingAdapter();
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config().copyWith(
        syncState: ChartSyncState.synced,
        serverVisualizationId: 'viz00000001',
      ));

      final pushed = await repo.pushPendingCharts();
      expect(pushed, 0);
    });

    test('a previously-created chart PUTs to its own object on a later push',
        () async {
      final adapter = _RecordingAdapter(statusCode: 200, body: {
        'httpStatus': 'OK',
        'response': {},
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config().copyWith(
        syncState: ChartSyncState.error,
        serverVisualizationId: 'vizExisting1',
        syncError: 'stale error to be cleared',
      ));

      await repo.pushPendingCharts();

      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, '/api/visualizations/vizExisting1.json');
      final saved = (await repo.getSavedCharts()).single;
      expect(saved.syncState, ChartSyncState.synced);
      expect(saved.serverVisualizationId, 'vizExisting1');
      expect(saved.syncError, isNull);
    });

    test('server rejection settles the chart as error with the message',
        () async {
      final adapter = _RecordingAdapter(statusCode: 409, body: {
        'httpStatus': 'Conflict',
        'message': 'Object referenced by another object.',
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config());

      final pushed = await repo.pushPendingCharts();

      expect(pushed, 0);
      final saved = (await repo.getSavedCharts()).single;
      expect(saved.syncState, ChartSyncState.error);
      expect(saved.syncError, 'Object referenced by another object.');
    });

    test('transport failure leaves the chart pending for the next attempt',
        () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);
      await repo.saveChart(config());

      final pushed = await repo.pushPendingCharts();

      expect(pushed, 0);
      final saved = (await repo.getSavedCharts()).single;
      expect(saved.syncState, ChartSyncState.pending);
    });

    test(
        'dataset metrics nest dataSet+metric (verified against a live '
        '2.40.1 server’s own saved visualizations)', () async {
      final adapter = _RecordingAdapter(statusCode: 201, body: {
        'response': {'uid': 'viz1'}
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);

      await repo.saveChart(config(
        dataType: ChartDataType.dataSet,
        items: const [ChartItemRef(id: 'dataSet0001', name: 'HMIS Monthly')],
        metric: DataSetMetric.expectedReports,
      ));
      await repo.pushPendingCharts();

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      final items = body['dataDimensionItems'] as List;
      expect(items.single['dataDimensionItemType'], 'REPORTING_RATE');
      final reportingRate = items.single['reportingRate'] as Map;
      expect((reportingRate['dataSet'] as Map)['id'], 'dataSet0001');
      expect(reportingRate['metric'], 'EXPECTED_REPORTS');

      // Confirmed live: columns[].items carries the PLAIN dataset id,
      // never a composite "dataSet.METRIC" string.
      final columns = (body['columns'] as List).single as Map;
      expect(columns['items'], [
        {'id': 'dataSet0001'}
      ]);
    });

    test('indicators and totals-only data elements nest a plain id',
        () async {
      final adapter = _RecordingAdapter(statusCode: 201, body: {
        'response': {'uid': 'viz1'}
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo = ChartRepositoryImpl(session: _TestSession(db), api: client);

      await repo.saveChart(config(items: const [
        ChartItemRef(id: 'indicator01', name: 'ANC 1st visit'),
      ]));
      await repo.pushPendingCharts();

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      final item = (body['dataDimensionItems'] as List).single as Map;
      expect(item['dataDimensionItemType'], 'INDICATOR');
      expect((item['indicator'] as Map)['id'], 'indicator01');
    });
  });
}

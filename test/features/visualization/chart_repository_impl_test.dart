import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
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
  });
}

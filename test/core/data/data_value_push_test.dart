import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/data_value_push.dart';
import 'package:hisp_mobile_trucker/core/data/data_value_store.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';

/// Replays one canned HTTP response (or a connection error) for every
/// request — the shapes below are captured from the real staging server
/// (DHIS2 2.40.1), which answers an import WITH conflicts as HTTP 409.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({this.statusCode = 200, this.body, this.failTransport = false});

  final int statusCode;
  final Map<String, dynamic>? body;
  final bool failTransport;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
    if (failTransport) {
      throw DioException.connectionError(
          requestOptions: options, reason: 'no route to host');
    }
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
  late DataValueStore store;

  const de1 = 'dataElem001';
  const de2 = 'dataElem002';
  const ou = 'orgUnit0001';
  const coc = 'catOptCmb01';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DataValueStore(db);
  });

  tearDown(() async => db.close());

  ApiClient clientWith(_CannedAdapter adapter) {
    final client = ApiClient.withBasicAuth(
        baseUrl: 'https://example.invalid', username: 'u', password: 'p');
    client.dio.httpClientAdapter = adapter;
    return client;
  }

  Future<List<DataValue>> queueTwoValues() async {
    for (final de in [de1, de2]) {
      await store.setValue(
        dataElementUid: de,
        period: '201811',
        orgUnitUid: ou,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '5',
      );
    }
    return store.pendingValues();
  }

  Map<String, dynamic> importSummary({
    required int ignored,
    List<Map<String, dynamic>> conflicts = const [],
    List<int> rejectedIndexes = const [],
  }) =>
      {
        'httpStatus': ignored > 0 ? 'Conflict' : 'OK',
        'status': ignored > 0 ? 'WARNING' : 'SUCCESS',
        'response': {
          'responseType': 'ImportSummary',
          'importCount': {'imported': 0, 'updated': 2 - ignored, 'ignored': ignored},
          'conflicts': conflicts,
          if (rejectedIndexes.isNotEmpty) 'rejectedIndexes': rejectedIndexes,
        },
      };

  test('clean 200 marks every value synced', () async {
    final values = await queueTwoValues();
    final result = await pushDataValueBatch(
      api: clientWith(_CannedAdapter(body: importSummary(ignored: 0))),
      store: store,
      values: values,
    );

    expect(result.accepted, 2);
    expect(result.rejected, 0);
    expect(await store.pendingValues(), isEmpty);
  });

  test('409 with conflict indexes flips ONLY the rejected value to error',
      () async {
    final values = await queueTwoValues();
    final result = await pushDataValueBatch(
      api: clientWith(_CannedAdapter(
        statusCode: 409,
        body: importSummary(
          ignored: 1,
          conflicts: [
            {
              'object': de1,
              'objects': {'dataElement': de1},
              'value': 'Data element not found or not accessible: `$de1`',
              'errorCode': 'E7610',
              'property': 'dataElement',
              'indexes': [0],
            }
          ],
          rejectedIndexes: [0],
        ),
      )),
      store: store,
      values: values,
    );

    expect(result.accepted, 1);
    expect(result.rejected, 1);
    expect(await store.pendingValues(), isEmpty,
        reason: 'a server verdict settles every value — no eternal retry');

    final rows = await db.select(db.dataValuesTable).get();
    final rejected = rows.singleWhere((r) => r.dataElementUid == de1);
    final accepted = rows.singleWhere((r) => r.dataElementUid == de2);
    expect(rejected.syncState, SyncState.error);
    expect(rejected.syncError, contains('not found'));
    expect(accepted.syncState, SyncState.synced);
  });

  test('transport failure leaves everything pending', () async {
    final values = await queueTwoValues();
    final result = await pushDataValueBatch(
      api: clientWith(_CannedAdapter(failTransport: true)),
      store: store,
      values: values,
    );

    expect(result.transportFailed, isTrue);
    expect((await store.pendingValues()).length, 2);
  });
}

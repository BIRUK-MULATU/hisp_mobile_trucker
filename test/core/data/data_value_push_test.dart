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

  /// The decoded request body of the last POST — lets a test assert the
  /// exact payload shape sent to the server.
  Map<String, dynamic>? lastRequestBody;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? __) async {
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = [for (final c in chunks) ...c];
      if (bytes.isNotEmpty) {
        lastRequestBody =
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }
    }
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

  test('a cleared cell goes up as a deletion, never as an empty value',
      () async {
    // A synced server value the user then wiped: stored locally as a
    // null value, promoted to pending.
    await store.setValue(
      dataElementUid: de1,
      period: '201811',
      orgUnitUid: ou,
      categoryOptionComboUid: coc,
      attributeOptionComboUid: coc,
      value: null,
    );
    final values = await store.pendingValues();
    final adapter = _CannedAdapter(body: importSummary(ignored: 0));

    await pushDataValueBatch(
      api: clientWith(adapter),
      store: store,
      values: values,
    );

    final sent = (adapter.lastRequestBody!['dataValues'] as List)
        .cast<Map<String, dynamic>>()
        .single;
    expect(sent['deleted'], isTrue,
        reason: 'empty value must be sent as deleted:true (avoids E7610)');
    expect(await store.pendingValues(), isEmpty);
  });

  test('server ignoring a no-op delete settles the row as synced, not error',
      () async {
    await store.setValue(
      dataElementUid: de1,
      period: '201811',
      orgUnitUid: ou,
      categoryOptionComboUid: coc,
      attributeOptionComboUid: coc,
      value: null,
    );
    final values = await store.pendingValues();

    final result = await pushDataValueBatch(
      api: clientWith(_CannedAdapter(
        statusCode: 409,
        body: importSummary(ignored: 1, rejectedIndexes: [0]),
      )),
      store: store,
      values: values,
    );

    expect(result.rejected, 0);
    final row = (await db.select(db.dataValuesTable).get()).single;
    expect(row.syncState, SyncState.synced);
  });

  test('a value invalid for its type is settled as error before the push',
      () async {
    await db.into(db.dataElementsTable).insert(
          DataElementsTableCompanion.insert(
            uid: de1,
            name: de1,
            displayName: de1,
            formName: de1,
            valueType: 'INTEGER_ZERO_OR_POSITIVE',
            categoryComboUid: coc,
          ),
        );
    // -5 into a zero-or-positive integer field, plus a valid sibling.
    await store.setValue(
      dataElementUid: de1,
      period: '201811',
      orgUnitUid: ou,
      categoryOptionComboUid: coc,
      attributeOptionComboUid: coc,
      value: '-5',
    );
    await store.setValue(
      dataElementUid: de2,
      period: '201811',
      orgUnitUid: ou,
      categoryOptionComboUid: coc,
      attributeOptionComboUid: coc,
      value: '7',
    );
    final values = await store.pendingValues();
    final adapter = _CannedAdapter(body: importSummary(ignored: 0));

    final result = await pushDataValueBatch(
      api: clientWith(adapter),
      store: store,
      values: values,
    );

    // The bad value never went up…
    final sent = (adapter.lastRequestBody!['dataValues'] as List)
        .cast<Map<String, dynamic>>();
    expect(sent.map((e) => e['dataElement']), [de2]);
    // …it's an error row now, with the client-side reason…
    final rows = await db.select(db.dataValuesTable).get();
    final bad = rows.singleWhere((r) => r.dataElementUid == de1);
    expect(bad.syncState, SyncState.error);
    expect(bad.syncError, contains('negative'));
    // …and the good sibling still synced.
    final good = rows.singleWhere((r) => r.dataElementUid == de2);
    expect(good.syncState, SyncState.synced);
    expect(result.rejected, 1);
    expect(result.accepted, 1);
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

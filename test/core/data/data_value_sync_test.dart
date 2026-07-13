import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/data_value_store.dart';
import 'package:hisp_mobile_trucker/core/data/data_value_sync.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';

/// Replays one canned dataValueSets response for every request (the
/// pull phase is the only network contact these tests exercise).
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({required this.body});

  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
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
  late DataValueStore store;

  const ds = 'dataSet0001';
  const de = 'dataElem001';
  const ou = 'orgUnit0001';
  const coc = 'catOptCmb01';
  const period = '201811';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DataValueStore(db);
  });

  tearDown(() async => db.close());

  ApiClient clientWith(Map<String, dynamic> body) {
    final client = ApiClient.withBasicAuth(
        baseUrl: 'https://example.invalid', username: 'u', password: 'p');
    client.dio.httpClientAdapter = _CannedAdapter(body: body);
    return client;
  }

  Map<String, dynamic> serverCell(String value, {DateTime? lastUpdated}) => {
        'dataValues': [
          {
            'dataElement': de,
            'period': period,
            'orgUnit': ou,
            'categoryOptionCombo': coc,
            'attributeOptionCombo': coc,
            'value': value,
            'lastUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
          },
        ],
      };

  Future<DataValueSyncResult> syncOnce(Map<String, dynamic> body) =>
      DataValueSync(db, clientWith(body)).syncForm(
        dataSetUid: ds,
        period: period,
        orgUnitUid: ou,
        dataElementUids: const [de],
        attributeOptionComboUid: coc,
      );

  group('drafts during pull', () {
    test('a newer server value never overwrites a local draft', () async {
      await store.setValue(
        dataElementUid: de,
        period: period,
        orgUnitUid: ou,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '5',
        draft: true,
      );

      // Server is unambiguously newer — under newest-wins it would
      // take the cell, but drafts are protected.
      final result = await syncOnce(serverCell('9',
          lastUpdated: DateTime.now().add(const Duration(hours: 1))));

      expect(result.localWon, 1);
      final row = (await db.select(db.dataValuesTable).get()).single;
      expect(row.value, '5', reason: 'the typed draft value must survive');
      expect(row.syncState, SyncState.draft,
          reason: 'still device-only until the user completes the form');
    });

    test('a draft equal to the server value settles as synced', () async {
      await store.setValue(
        dataElementUid: de,
        period: period,
        orgUnitUid: ou,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '5',
        draft: true,
      );

      final result = await syncOnce(serverCell('5'));

      expect(result.equalSkipped, 1);
      final row = (await db.select(db.dataValuesTable).get()).single;
      expect(row.syncState, SyncState.synced,
          reason: 'nothing left to send — the server already has it');
    });
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/data_value_store.dart';
import 'package:hisp_mobile_trucker/core/data/data_value_sync.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/metadata/category_option_combo.dart';
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

  group('duplicate default COC on pull', () {
    const duplicateDefaultUid = 'ed678csgTm8';

    Future<void> seedCombo(String uid) => db
        .into(db.categoryOptionCombosTable)
        .insert(CategoryOptionCombosTableCompanion.insert(
          uid: uid,
          name: 'default',
          categoryComboUid: 'catCombo001',
        ));

    test(
        'a value pulled under a non-canonical "default" combo is still '
        'readable through the canonical uid', () async {
      // This device's cached metadata has BOTH combos this HMIS
      // instance is known to carry under the name 'default' — the
      // canonical one and (at least) one duplicate.
      await seedCombo(canonicalDefaultComboUid);
      await seedCombo(duplicateDefaultUid);

      // The server hands back the cell keyed on the DUPLICATE uid —
      // exactly what happens for values recorded before the duplicate
      // was ever detected/resolved.
      final result = await DataValueSync(db, clientWith({
        'dataValues': [
          {
            'dataElement': de,
            'period': period,
            'orgUnit': ou,
            'categoryOptionCombo': duplicateDefaultUid,
            'attributeOptionCombo': duplicateDefaultUid,
            'value': '42',
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        ],
      })).syncForm(
        dataSetUid: ds,
        period: period,
        orgUnitUid: ou,
        dataElementUids: const [de],
        attributeOptionComboUid: canonicalDefaultComboUid,
      );
      expect(result.pulled, true);

      // The read path (DataEntryRepositoryImpl / the entry grid) always
      // filters by the CANONICAL uid — without the remap, this would
      // come back empty even though the pull "succeeded".
      final rows = await store.valuesForForm(
        period: period,
        orgUnitUid: ou,
        attributeOptionComboUid: canonicalDefaultComboUid,
        dataElementUids: const [de],
      );
      expect(rows, hasLength(1));
      expect(rows.single.value, '42');
      expect(rows.single.categoryOptionComboUid, canonicalDefaultComboUid);
      expect(rows.single.attributeOptionComboUid, canonicalDefaultComboUid);
    });
  });
}

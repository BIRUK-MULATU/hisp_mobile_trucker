import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/completeness.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';

/// Records every request and answers each with one canned response —
/// lets the tests assert the exact wire shape of a push.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200, this.body = const {}});

  final int statusCode;
  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
    requests.add(options);
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
  late CompletenessStore store;

  const ds = 'dataSet0001';
  const ou = 'orgUnit0001';
  const period = '201811';
  const defaultAoc = 'defaultCoc1';
  const customAoc = 'customCoc01';
  const customCombo = 'catCombo001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = CompletenessStore(db);
  });

  tearDown(() async => db.close());

  Future<void> seedCoc(String uid, String name, String comboUid,
      {List<String> options = const []}) async {
    await db.into(db.categoryOptionCombosTable).insert(
          CategoryOptionCombosTableCompanion.insert(
            uid: uid,
            name: name,
            categoryComboUid: comboUid,
          ),
        );
    for (final option in options) {
      await db.into(db.categoryOptionComboOptionsTable).insert(
            CategoryOptionComboOptionsTableCompanion.insert(
              categoryOptionComboUid: uid,
              categoryOptionUid: option,
            ),
          );
    }
  }

  (CompletenessSync, _RecordingAdapter) syncWith(
      {int statusCode = 200, Map<String, dynamic> body = const {}}) {
    final adapter = _RecordingAdapter(statusCode: statusCode, body: body);
    final client = ApiClient.withBasicAuth(
        baseUrl: 'https://example.invalid', username: 'u', password: 'p');
    client.dio.httpClientAdapter = adapter;
    return (CompletenessSync(db, client), adapter);
  }

  group('un-complete DELETE', () {
    Future<void> queueUncomplete(String aoc) => store.setComplete(
          dataSetUid: ds,
          period: period,
          orgUnitUid: ou,
          attributeOptionComboUid: aoc,
          completed: false,
        );

    test('default attribute combo sends no cc/cp', () async {
      await seedCoc(defaultAoc, 'default', 'defCombo001');
      await queueUncomplete(defaultAoc);

      final (sync, adapter) = syncWith();
      expect(await sync.pushPending(), 1);

      final req = adapter.requests.single;
      expect(req.method, 'DELETE');
      expect(req.queryParameters['ds'], ds);
      expect(req.queryParameters['pe'], period);
      expect(req.queryParameters['ou'], ou);
      expect(req.queryParameters.containsKey('cc'), isFalse);
      expect(req.queryParameters.containsKey('cp'), isFalse);
    });

    test('non-default attribute combo is addressed with cc + cp', () async {
      await seedCoc(customAoc, 'Male, Urban', customCombo,
          options: ['catOption01', 'catOption02']);
      await queueUncomplete(customAoc);

      final (sync, adapter) = syncWith();
      expect(await sync.pushPending(), 1);

      final req = adapter.requests.single;
      expect(req.queryParameters['cc'], customCombo);
      expect((req.queryParameters['cp'] as String).split(';').toSet(),
          {'catOption01', 'catOption02'},
          reason: 'cp = the combo\'s option uids, ;-joined');
    });

    test('combo missing from local cache falls back to no cc/cp', () async {
      await queueUncomplete(customAoc); // nothing seeded

      final (sync, adapter) = syncWith();
      expect(await sync.pushPending(), 1);
      expect(adapter.requests.single.queryParameters.containsKey('cc'),
          isFalse);
    });

    test('a pushed un-completion settles as synced', () async {
      await seedCoc(defaultAoc, 'default', 'defCombo001');
      await queueUncomplete(defaultAoc);

      final (sync, _) = syncWith();
      await sync.pushPending();

      final row = await store.statusOf(
        dataSetUid: ds,
        period: period,
        orgUnitUid: ou,
        attributeOptionComboUid: defaultAoc,
      );
      expect(row!.completed, isFalse);
      expect(row.syncState, SyncState.synced);
    });
  });

  test('server 409 verdict settles the registration as error, not '
      'eternal retry', () async {
    await store.setComplete(
      dataSetUid: ds,
      period: period,
      orgUnitUid: ou,
      attributeOptionComboUid: defaultAoc,
      completed: true,
    );

    final (sync, _) = syncWith(statusCode: 409, body: {
      'status': 'ERROR',
      'conflicts': [
        {'object': ds, 'value': 'Period is not open for this data set'},
      ],
    });
    expect(await sync.pushPending(), 0);

    final row = await store.statusOf(
      dataSetUid: ds,
      period: period,
      orgUnitUid: ou,
      attributeOptionComboUid: defaultAoc,
    );
    expect(row!.syncState, SyncState.error);
    expect(row.syncError, contains('Period is not open'));
    expect(await store.pending(), isEmpty,
        reason: 'a rejected registration must leave the retry queue');
  });
}

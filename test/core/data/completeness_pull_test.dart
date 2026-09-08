import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/completeness.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';

class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.body);
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? _, Future<void>? __) async {
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;

  const ds = 'dataSet0001';
  const ou = 'orgUnit0001';
  const coc = 'HllvX50cXC0'; // canonical default
  const period = '201811';

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  ApiClient clientWith(Map<String, dynamic> body) {
    final c = ApiClient.withBasicAuth(
        baseUrl: 'https://example.invalid', username: 'u', password: 'p');
    c.dio.httpClientAdapter = _CannedAdapter(body);
    return c;
  }

  Map<String, dynamic> regBody({required bool completed}) => {
        'completeDataSetRegistrations': [
          {
            'dataSet': ds,
            'period': period,
            'organisationUnit': ou,
            'attributeOptionCombo': coc,
            'completed': completed,
            'date': '2018-08-05T00:00:00.000',
          }
        ]
      };

  test('mirrors a server completion locally as synced', () async {
    final applied = await CompletenessSync(db, clientWith(regBody(completed: true)))
        .pullRecent(orgUnitUids: [ou], since: DateTime(2018));
    expect(applied, 1);

    final row = (await db.select(db.completeDataSetRegistrationsTable).get())
        .single;
    expect(row.completed, isTrue);
    expect(row.syncState, SyncState.synced);
  });

  test('leaves a locally pending completion untouched', () async {
    await db.into(db.completeDataSetRegistrationsTable).insert(
          CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: ds,
            period: period,
            orgUnitUid: ou,
            attributeOptionComboUid: coc,
            completed: false, // a pending UN-complete
            date: DateTime(2018, 8, 9),
            syncState: SyncState.pending,
            lastModified: DateTime(2018, 8, 9),
          ),
        );

    final applied = await CompletenessSync(db, clientWith(regBody(completed: true)))
        .pullRecent(orgUnitUids: [ou], since: DateTime(2018));
    expect(applied, 0);

    final row = (await db.select(db.completeDataSetRegistrationsTable).get())
        .single;
    expect(row.completed, isFalse);
    expect(row.syncState, SyncState.pending);
  });

  test('completed:false server rows are ignored', () async {
    final applied =
        await CompletenessSync(db, clientWith(regBody(completed: false)))
            .pullRecent(orgUnitUids: [ou], since: DateTime(2018));
    expect(applied, 0);
    expect(await db.select(db.completeDataSetRegistrationsTable).get(), isEmpty);
  });
}

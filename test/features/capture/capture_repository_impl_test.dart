import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';
import 'package:hisp_mobile_trucker/features/capture/data/repositories/capture_repository_impl.dart';
import 'package:hisp_mobile_trucker/features/capture/domain/entities/report_instance_entity.dart';

/// A session whose database is the test's in-memory one — no login.
class _TestSession extends SessionService {
  _TestSession(this._testDb);
  final AppDatabase _testDb;

  @override
  AppDatabase get db => _testDb;
}

/// Replays one canned JSON response for EVERY request (fine for these
/// tests — each one only issues a single kind of request), and
/// records the request uris seen for assertions.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({required this.body});

  final Map<String, dynamic> body;
  final List<Uri> requestedUris = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _,
      Future<void>? __) async {
    requestedUris.add(options.uri);
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

/// Simulates being genuinely offline DESPITE a configured ApiClient —
/// e.g. logged in previously, but no network route right now. This is
/// the actual failure mode a non-null ApiClient does NOT rule out.
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

void main() {
  late AppDatabase db;
  late CaptureRepositoryImpl repository;

  const ds1 = 'dataSet0001';
  const ds2 = 'dataSet0002';
  const de1 = 'dataElem001';
  const ou1 = 'orgUnit0001';
  const coc = 'catOptCmb01';
  const period = '201811';

  final t0 = DateTime(2026, 7, 1);
  final t1 = DateTime(2026, 7, 2);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CaptureRepositoryImpl(session: _TestSession(db));

    await db.into(db.dataSetsTable).insert(
          DataSetsTableCompanion.insert(
            uid: ds1,
            name: 'HMIS Monthly',
            displayName: 'HMIS Monthly',
            periodType: 'Monthly',
            categoryComboUid: coc,
          ),
        );
    await db.into(db.orgUnitsTable).insert(
          OrgUnitsTableCompanion.insert(
            uid: ou1,
            name: 'Health Post A',
            displayName: 'Health Post A',
            path: '/$ou1',
          ),
        );
    await db.into(db.dataSetElementsTable).insert(
          DataSetElementsTableCompanion.insert(
            dataSetUid: ds1,
            dataElementUid: de1,
            categoryComboUid: coc,
          ),
        );
  });

  tearDown(() async => db.close());

  Future<void> insertCompletion({
    String dataSet = ds1,
    String attributeOptionComboUid = coc,
    required SyncState syncState,
    DateTime? at,
  }) =>
      db.into(db.completeDataSetRegistrationsTable).insert(
            CompleteDataSetRegistrationsTableCompanion.insert(
              dataSetUid: dataSet,
              period: period,
              orgUnitUid: ou1,
              attributeOptionComboUid: attributeOptionComboUid,
              completed: true,
              date: at ?? t0,
              syncState: syncState,
              lastModified: at ?? t0,
            ),
          );

  Future<void> insertValue({
    required SyncState syncState,
    DateTime? at,
  }) =>
      db.into(db.dataValuesTable).insert(
            DataValuesTableCompanion.insert(
              dataElementUid: de1,
              period: period,
              orgUnitUid: ou1,
              categoryOptionComboUid: coc,
              attributeOptionComboUid: coc,
              syncState: syncState,
              lastModified: at ?? t0,
            ),
          );

  group('getUserReports', () {
    test('no local work at all → empty list', () async {
      expect(await repository.getUserReports(), isEmpty);
    });

    test('synced completion → completed and synced', () async {
      await insertCompletion(syncState: SyncState.synced);

      final report = (await repository.getUserReports()).single;
      expect(report.dataSetId, ds1);
      expect(report.dataSetName, 'HMIS Monthly');
      expect(report.orgUnitName, 'Health Post A');
      expect(report.status, ReportStatus.completed);
      expect(report.synced, isTrue);
    });

    test('queued completion → completed but not synced', () async {
      await insertCompletion(syncState: SyncState.pending);

      final report = (await repository.getUserReports()).single;
      expect(report.status, ReportStatus.completed);
      expect(report.synced, isFalse);
    });

    test('a draft reopens a completed report', () async {
      await insertCompletion(syncState: SyncState.synced);
      await insertValue(syncState: SyncState.draft, at: t1);

      final report = (await repository.getUserReports()).single;
      expect(report.status, ReportStatus.incomplete,
          reason: 'draft work means the report is being reworked');
      expect(report.synced, isFalse);
      expect(report.lastModified, t1, reason: 'the newest local touch wins');
    });

    test('unsynced values map to their dataset through dataSetElements',
        () async {
      await insertValue(syncState: SyncState.pending);

      final report = (await repository.getUserReports()).single;
      expect(report.dataSetId, ds1);
      expect(report.status, ReportStatus.incomplete);
      expect(report.synced, isFalse);
    });

    test('fully synced values alone are not "my reports" work', () async {
      await insertValue(syncState: SyncState.synced);
      expect(await repository.getUserReports(), isEmpty);
    });

    test('a report whose dataset metadata is gone is dropped', () async {
      await insertCompletion(dataSet: ds2, syncState: SyncState.synced);
      expect(await repository.getUserReports(), isEmpty,
          reason: 'nothing to open when the dataset is unassigned');
    });

    test('a Disease Registration report is included and flagged', () async {
      const diseaseDs = 'dataSet0004';
      const categoryAttr = 'attribute01';
      await db.into(db.dataSetsTable).insert(
            DataSetsTableCompanion.insert(
              uid: diseaseDs,
              name: '16 - Disease Registration',
              displayName: '16 - Disease Registration',
              periodType: 'Monthly',
              categoryComboUid: coc,
            ),
          );
      await db.into(db.attributesTable).insert(
            AttributesTableCompanion.insert(
              uid: categoryAttr,
              name: 'Dataset Category',
              displayName: 'Dataset Category',
              valueType: 'TEXT',
            ),
          );
      await db.into(db.attributeValuesTable).insert(
            AttributeValuesTableCompanion.insert(
              objectType: 'dataSet',
              objectUid: diseaseDs,
              attributeUid: categoryAttr,
              value: 'Disease',
            ),
          );
      await insertCompletion(dataSet: diseaseDs, syncState: SyncState.synced);
      await insertCompletion(syncState: SyncState.synced); // routine (ds1)

      final reports = await repository.getUserReports();
      expect(reports, hasLength(2),
          reason: 'Routine and Disease Registration reports now share '
              'one merged list');

      final diseaseReport =
          reports.singleWhere((r) => r.dataSetId == diseaseDs);
      expect(diseaseReport.isDiseaseRegistration, isTrue,
          reason: 'flagged so the reopened form gets the disease styling');

      final routineReport = reports.singleWhere((r) => r.dataSetId == ds1);
      expect(routineReport.isDiseaseRegistration, isFalse);
    });

    test(
        'two attribute option combos of the same dataset/period/org unit '
        'stay separate reports', () async {
      const opdCured = 'cocOpdCure1';
      const ipdDied = 'cocIpdDied1';
      await db.into(db.categoryOptionCombosTable).insert(
            CategoryOptionCombosTableCompanion.insert(
              uid: opdCured,
              name: 'OPD, Cured',
              categoryComboUid: coc,
            ),
          );
      await db.into(db.categoryOptionCombosTable).insert(
            CategoryOptionCombosTableCompanion.insert(
              uid: ipdDied,
              name: 'IPD, Died',
              categoryComboUid: coc,
            ),
          );
      await insertCompletion(
          attributeOptionComboUid: opdCured, syncState: SyncState.synced);
      await insertCompletion(
          attributeOptionComboUid: ipdDied, syncState: SyncState.synced);

      final reports = await repository.getUserReports();
      expect(reports, hasLength(2),
          reason: 'same dataset/period/org unit but different category '
              'combo cells are distinct reports, not one merged report');

      final labels = {for (final r in reports) r.attributeOptionComboLabel};
      expect(labels, {'OPD, Cured', 'IPD, Died'});
    });

    test('the default attribute option combo has no label', () async {
      await insertCompletion(syncState: SyncState.synced);
      final report = (await repository.getUserReports()).single;
      expect(report.attributeOptionComboUid, coc);
      expect(report.attributeOptionComboLabel, isNull,
          reason: 'nothing distinguishing to show for the trivial combo');
    });

    test('sorted newest local change first', () async {
      await insertCompletion(syncState: SyncState.synced, at: t0);

      const dsB = 'dataSet0003';
      await db.into(db.dataSetsTable).insert(
            DataSetsTableCompanion.insert(
              uid: dsB,
              name: 'Weekly B',
              displayName: 'Weekly B',
              periodType: 'Weekly',
              categoryComboUid: coc,
            ),
          );
      await insertCompletion(dataSet: dsB, syncState: SyncState.synced, at: t1);

      final reports = await repository.getUserReports();
      expect([for (final r in reports) r.dataSetId], [dsB, ds1]);
    });
  });

  group('getOrgUnitChildren — beyond the synced depth bound', () {
    test('offline (no api): nothing locally synced means nothing shown, '
        'no live attempt', () async {
      // ou1 has no children in orgUnitsTable at all.
      final children = await repository.getOrgUnitChildren(ou1);
      expect(children, isEmpty);
    });

    test('online: falls back to a live query when nothing is synced '
        'locally for this node', () async {
      final adapter = _CannedAdapter(body: {
        'organisationUnits': [
          {
            'id': 'healthCenter1',
            'displayName': 'Health Center',
            'path': '/national/$ou1/healthCenter1',
            'children': [
              {'id': 'x'}
            ],
          },
        ],
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      final children = await repo.getOrgUnitChildren(ou1);

      expect(adapter.requestedUris.single.path,
          '/api/organisationUnits.json');
      expect(adapter.requestedUris.single.queryParameters['filter'],
          'parent.id:eq:$ou1');
      expect(children, hasLength(1));
      expect(children.single.id, 'healthCenter1');
      expect(children.single.childCount, 1,
          reason: 'derived from the nested children[] the live query asked for');
    });

    test('a capture root\'s direct child with zero LOCAL grandchildren '
        'still gets an expand arrow when a live check finds real ones',
        () async {
      // ou1 is a capture root; child1 is its direct child, synced with
      // (correctly) zero children of its own locally — but it DOES
      // have children on the server.
      await (db.update(db.orgUnitsTable)..where((t) => t.uid.equals(ou1)))
          .write(const OrgUnitsTableCompanion(isUserCaptureRoot: Value(true)));
      const child1 = 'phcuA000001';
      await db.into(db.orgUnitsTable).insert(
            OrgUnitsTableCompanion.insert(
              uid: child1,
              name: 'PHCU A',
              displayName: 'PHCU A',
              parentUid: const Value(ou1),
              path: '/$ou1/$child1',
            ),
          );

      final adapter = _CannedAdapter(body: {
        'organisationUnits': [
          {'id': 'someGrandchild'},
        ],
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      final children = await repo.getOrgUnitChildren(ou1);

      expect(children.single.id, child1);
      expect(children.single.childCount, greaterThan(0),
          reason: 'the live existence check found real grandchildren, so '
              'the local (always-0) count must not win');
    });
  });

  group('getDataSetsForOrgUnit — beyond the synced depth bound', () {
    const facilityUid = 'healthCntr1';

    test('online: live-fetches the facility\'s dataset assignment and '
        'CACHES it, so a later call succeeds purely locally', () async {
      final adapter = _CannedAdapter(body: {
        'id': facilityUid,
        'name': 'Health Center B',
        'displayName': 'Health Center B',
        'parent': {'id': ou1, 'name': 'Health Post A'},
        'path': '/$ou1/$facilityUid',
        'dataSets': [
          {'id': ds1},
        ],
      });
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = adapter;
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      final live = await repo.getDataSetsForOrgUnit(facilityUid);
      expect(live.map((d) => d.id), [ds1]);
      expect(adapter.requestedUris.single.path,
          '/api/organisationUnits/$facilityUid.json');

      // Cached: the facility row and its dataset link both now exist
      // locally, so a fresh (api-less/offline) repository sees them
      // without any live call at all.
      final offlineRepo = CaptureRepositoryImpl(session: _TestSession(db));
      final cached = await offlineRepo.getDataSetsForOrgUnit(facilityUid);
      expect(cached.map((d) => d.id), [ds1]);

      final savedOrgUnit = await (db.select(db.orgUnitsTable)
            ..where((t) => t.uid.equals(facilityUid)))
          .getSingle();
      expect(savedOrgUnit.parentUid, ou1);
    });

    test('offline: no api, no local assignment — falls through to the '
        '"no metadata" handling untouched (dataset metadata IS present, '
        'so this just returns empty, no crash)', () async {
      final result = await repository.getDataSetsForOrgUnit(facilityUid);
      expect(result, isEmpty);
    });

    test('a CONFIGURED api that fails with a connection error (genuinely '
        'offline despite being logged in) degrades gracefully instead of '
        'throwing — regression for a real bug caught in the running app',
        () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      final result = await repo.getDataSetsForOrgUnit(facilityUid);
      expect(result, isEmpty);
    });
  });

  group('live fallback degrades gracefully when actually offline '
      '(configured api, but the request itself fails)', () {
    test('getOrgUnitChildren on an unsynced node returns empty, not a '
        'thrown exception', () async {
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      expect(await repo.getOrgUnitChildren(ou1), isEmpty);
    });

    test('getOrgUnitChildren\'s boundary childCount check failing leaves '
        'the local (0) count rather than throwing', () async {
      await (db.update(db.orgUnitsTable)..where((t) => t.uid.equals(ou1)))
          .write(const OrgUnitsTableCompanion(isUserCaptureRoot: Value(true)));
      const child1 = 'phcuA000001';
      await db.into(db.orgUnitsTable).insert(
            OrgUnitsTableCompanion.insert(
              uid: child1,
              name: 'PHCU A',
              displayName: 'PHCU A',
              parentUid: const Value(ou1),
              path: '/$ou1/$child1',
            ),
          );
      final client = ApiClient.withBasicAuth(
          baseUrl: 'https://example.invalid', username: 'u', password: 'p');
      client.dio.httpClientAdapter = _ThrowingAdapter();
      final repo =
          CaptureRepositoryImpl(session: _TestSession(db), api: client);

      final children = await repo.getOrgUnitChildren(ou1);
      expect(children.single.childCount, 0);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/features/capture/data/repositories/capture_repository_impl.dart';
import 'package:hisp_mobile_trucker/features/capture/domain/entities/report_instance_entity.dart';

/// A session whose database is the test's in-memory one — no login.
class _TestSession extends SessionService {
  _TestSession(this._testDb);
  final AppDatabase _testDb;

  @override
  AppDatabase get db => _testDb;
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
    required SyncState syncState,
    DateTime? at,
  }) =>
      db.into(db.completeDataSetRegistrationsTable).insert(
            CompleteDataSetRegistrationsTableCompanion.insert(
              dataSetUid: dataSet,
              period: period,
              orgUnitUid: ou1,
              attributeOptionComboUid: coc,
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
      expect(report.lastModified, t1,
          reason: 'the newest local touch wins');
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
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/data/ethiopian_calendar.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/features/capture/data/repositories/capture_repository_impl.dart';
import 'package:hisp_mobile_trucker/features/capture/domain/entities/expected_report_entity.dart';

class _TestSession extends SessionService {
  _TestSession(this._db);
  final AppDatabase _db;
  @override
  AppDatabase get db => _db;
}

void main() {
  late AppDatabase db;
  late CaptureRepositoryImpl repo;

  const root = 'captureRoot';
  const facility = 'facility001';
  const outsider = 'outsideOu01';
  const ds = 'monthlyDs01';
  const de = 'dataElem001';
  const coc = 'catOptCmb01';

  late String currentPeriod;
  late String lastPeriod;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CaptureRepositoryImpl(session: _TestSession(db));

    await db.into(db.orgUnitsTable).insert(OrgUnitsTableCompanion.insert(
          uid: root,
          name: 'Woreda',
          displayName: 'Woreda',
          path: '/$root',
          isUserCaptureRoot: const Value(true),
        ));
    await db.into(db.orgUnitsTable).insert(OrgUnitsTableCompanion.insert(
          uid: facility,
          name: 'Health Post A',
          displayName: 'Health Post A',
          path: '/$root/$facility',
          parentUid: const Value(root),
        ));
    // `outsider` deliberately has NO orgUnitsTable row — it stands for
    // an assignment to an org unit this device doesn't know locally.
    await db.into(db.dataSetsTable).insert(DataSetsTableCompanion.insert(
          uid: ds,
          name: 'HMIS Monthly',
          displayName: 'HMIS Monthly',
          periodType: 'Monthly',
          categoryComboUid: coc,
          expiryDays: const Value(10),
        ));
    await db.into(db.dataSetElementsTable).insert(
          DataSetElementsTableCompanion.insert(
              dataSetUid: ds, dataElementUid: de, categoryComboUid: coc),
        );
    // Trivial default combo so needsComboPick == false.
    await db.into(db.categoryCombosTable).insert(
          CategoryCombosTableCompanion.insert(
              uid: coc, name: 'default', displayName: 'default'),
        );

    final periods =
        EthiopianCalendar.generatePeriods(periodType: 'Monthly', count: 2);
    currentPeriod = periods[0].id;
    lastPeriod = periods[1].id;
  });

  tearDown(() async => db.close());

  Future<void> assign(String orgUnit) =>
      db.into(db.dataSetOrgUnitsTable).insert(
            DataSetOrgUnitsTableCompanion.insert(
                dataSetUid: ds, orgUnitUid: orgUnit),
          );

  test('lists the assigned dataset for the current open period', () async {
    await assign(facility);
    final expected = await repo.getExpectedReports();

    final ids = expected.map((e) => e.periodId).toSet();
    expect(ids, contains(currentPeriod));
    final cur = expected.firstWhere((e) => e.periodId == currentPeriod);
    expect(cur.dataSetId, ds);
    expect(cur.orgUnitId, facility);
    expect(cur.orgUnitName, 'Health Post A');
    expect(cur.needsComboPick, isFalse);
    expect(cur.localStarted, isFalse);
    expect(cur.lockDate, isNotNull);
  });

  test('a completed period is excluded', () async {
    await assign(facility);
    await db.into(db.completeDataSetRegistrationsTable).insert(
          CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: ds,
            period: currentPeriod,
            orgUnitUid: facility,
            attributeOptionComboUid: coc,
            completed: true,
            date: DateTime.now(),
            syncState: SyncState.synced,
            lastModified: DateTime.now(),
          ),
        );
    final expected = await repo.getExpectedReports();
    expect(expected.map((e) => e.periodId), isNot(contains(currentPeriod)));
  });

  test('an assignment to an org unit not known locally is ignored', () async {
    await assign(outsider);
    expect(await repo.getExpectedReports(), isEmpty);
  });

  test('the previous month is overdue, the current one is not', () async {
    await assign(facility);
    final expected = await repo.getExpectedReports();
    final last = expected.where((e) => e.periodId == lastPeriod);
    final cur = expected.firstWhere((e) => e.periodId == currentPeriod);
    expect(last, isNotEmpty);
    expect(last.single.urgency, ReportUrgency.overdue);
    expect(cur.urgency, isNot(ReportUrgency.overdue));
    // Overdue sorts ahead of the current period.
    expect(expected.first.urgency, ReportUrgency.overdue);
  });

  test('everything is expired once the clock is far in the future', () async {
    await assign(facility);
    await db.setSyncInfo('clockHighWaterMark',
        DateTime.now().add(const Duration(days: 3650)).toIso8601String());
    expect(await repo.getExpectedReports(), isEmpty);
  });

  test('local data marks the report as started', () async {
    await assign(facility);
    await db.into(db.dataValuesTable).insert(DataValuesTableCompanion.insert(
          dataElementUid: de,
          period: currentPeriod,
          orgUnitUid: facility,
          categoryOptionComboUid: coc,
          attributeOptionComboUid: coc,
          syncState: SyncState.draft,
          lastModified: DateTime.now(),
        ));
    final cur = (await repo.getExpectedReports())
        .firstWhere((e) => e.periodId == currentPeriod);
    expect(cur.localStarted, isTrue);
  });
}

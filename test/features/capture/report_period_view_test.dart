import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/auth/session_service.dart';
import 'package:hisp_mobile_trucker/core/data/ethiopian_calendar.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/features/capture/data/repositories/capture_repository_impl.dart';
import 'package:hisp_mobile_trucker/features/capture/presentation/views/report_period_view.dart';

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
  const facility1 = 'facility001';
  const facility2 = 'facility002';
  const ds = 'monthlyDs01';
  const de = 'dataElem001';
  const coc = 'catOptCmb01';

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
    for (final (uid, name) in [
      (facility1, 'Health Post A'),
      (facility2, 'Health Post B'),
    ]) {
      await db.into(db.orgUnitsTable).insert(OrgUnitsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: name,
            path: '/$root/$uid',
            parentUid: const Value(root),
          ));
    }
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
    await db.into(db.dataSetOrgUnitsTable).insert(
          DataSetOrgUnitsTableCompanion.insert(
              dataSetUid: ds, orgUnitUid: facility1),
        );
    await db.into(db.dataSetOrgUnitsTable).insert(
          DataSetOrgUnitsTableCompanion.insert(
              dataSetUid: ds, orgUnitUid: facility2),
        );

    // One local draft so the "worked on reports" list below the band
    // has a row — otherwise the sync summary bar never renders and the
    // overflow (band + bar taller than the body) wouldn't reproduce.
    await db.into(db.dataValuesTable).insert(DataValuesTableCompanion.insert(
          dataElementUid: de,
          period: EthiopianCalendar.generatePeriods(
                  periodType: 'Monthly', count: 1)
              .first
              .id,
          orgUnitUid: facility1,
          categoryOptionComboUid: coc,
          attributeOptionComboUid: coc,
          syncState: SyncState.draft,
          lastModified: DateTime.now(),
        ));
  });

  tearDown(() async => db.close());

  testWidgets(
      'the "Reports to fill" dashboard card swaps the list for the '
      'outstanding reports without overflowing a short, large-font screen',
      (tester) async {
    // A short phone in logical pixels, with accessibility text scaling
    // on. Together these make the four dashboard cards + the opened
    // outstanding list taller than the body; the whole stack scrolls
    // so a RenderFlex overflow is impossible.
    await tester.binding.setSurfaceSize(const Size(360, 420));
    tester.platformDispatcher.textScaleFactorTestValue = 1.75;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Capture')),
        body: ReportPeriodView(repository: repo),
      ),
    ));
    await tester.pumpAndSettle();

    // All four dashboard cards render, including the new one.
    // (Synced/Unsynced also appear as report-card chips, hence
    // findsWidgets rather than an exact count.)
    expect(find.text('Synced'), findsWidgets);
    expect(find.text('Unsynced'), findsWidgets);
    expect(find.text('Sync Error'), findsOneWidget);
    expect(find.text('Reports to fill'), findsOneWidget);

    // Two facilities × open periods → the outstanding list is long.
    await tester.tap(find.text('Reports to fill'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportPeriodView), findsOneWidget);

    final overflowed = <String>[];
    Object? e;
    while ((e = tester.takeException()) != null) {
      overflowed.add(e.toString());
    }
    expect(
      overflowed.where((s) => s.contains('overflowed')),
      isEmpty,
      reason: overflowed.isEmpty
          ? null
          : 'unexpected RenderFlex overflow:\n${overflowed.join('\n')}',
    );
  });
}
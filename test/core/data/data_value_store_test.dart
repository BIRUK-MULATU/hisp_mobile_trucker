import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/data_value_store.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late DataValueStore store;

  const ds1 = 'dataSet0001';
  const ds2 = 'dataSet0002';
  const de1 = 'dataElem001';
  const ou1 = 'orgUnit0001';
  const ou2 = 'orgUnit0002';
  const coc = 'catOptCmb01';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DataValueStore(db);
    // ds1 contains de1; ds2 has no elements (completion-only case).
    await db.into(db.dataSetElementsTable).insert(
          DataSetElementsTableCompanion.insert(
            dataSetUid: ds1,
            dataElementUid: de1,
            categoryComboUid: coc,
          ),
        );
  });

  tearDown(() async => db.close());

  Future<void> saveValue() => store.setValue(
        dataElementUid: de1,
        period: '201811',
        orgUnitUid: ou1,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '5',
      );

  test('pending value flags its dataset at that org unit only', () async {
    expect(await store.unsyncedDataSetsAt(ou1), isEmpty);

    await saveValue();
    expect(await store.unsyncedDataSetsAt(ou1), {ds1});
    expect(await store.unsyncedDataSetsAt(ou2), isEmpty,
        reason: 'the queued value belongs to ou1, not ou2');
  });

  test('synced value clears the flag; error keeps it', () async {
    await saveValue();
    final row = (await store.pendingValues()).single;

    await store.markSynced(row);
    expect(await store.unsyncedDataSetsAt(ou1), isEmpty);

    await store.markError(row, 'value_not_numeric');
    expect(await store.unsyncedDataSetsAt(ou1), {ds1},
        reason: 'rejected values are still un-uploaded work');
  });

  test('pending completion flags its dataset directly', () async {
    await db.into(db.completeDataSetRegistrationsTable).insert(
          CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: ds2,
            period: '201811',
            orgUnitUid: ou1,
            attributeOptionComboUid: coc,
            completed: true,
            date: DateTime.now(),
            syncState: SyncState.pending,
            lastModified: DateTime.now(),
          ),
        );
    expect(await store.unsyncedDataSetsAt(ou1), {ds2});
  });
}

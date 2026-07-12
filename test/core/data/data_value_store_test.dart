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

  group('drafts', () {
    Future<void> saveDraft() => store.setValue(
          dataElementUid: de1,
          period: '201811',
          orgUnitUid: ou1,
          categoryOptionComboUid: coc,
          attributeOptionComboUid: coc,
          value: '5',
          draft: true,
        );

    test('a draft is invisible to every push query', () async {
      await saveDraft();
      expect(await store.pendingValues(), isEmpty,
          reason: 'drafts must never be picked up by a push');
      expect(await store.pendingCount(), 0);
      expect(await store.draftCount(), 1);
    });

    test('a draft still counts as unsynced work', () async {
      await saveDraft();
      expect(await store.unsyncedDataSetsAt(ou1), {ds1},
          reason: 'draft work is not on the server');
      expect(await hasUnsyncedLocalData(db), isTrue,
          reason: 'clock must not re-anchor over draft stamps');
    });

    test('promoteDrafts flips the form to pending, scoped to its '
        'elements', () async {
      await saveDraft();

      // Different element (other dataset) — must not be promoted.
      await store.setValue(
        dataElementUid: 'dataElem002',
        period: '201811',
        orgUnitUid: ou1,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '7',
        draft: true,
      );

      final promoted = await store.promoteDrafts(
        period: '201811',
        orgUnitUid: ou1,
        attributeOptionComboUid: coc,
        dataElementUids: [de1],
      );
      expect(promoted, 1);
      expect((await store.pendingValues()).single.dataElementUid, de1);
      expect(await store.draftCount(), 1,
          reason: 'the other dataset\'s draft stays a draft');
    });
  });

  group('orgUnitsWithWork', () {
    test('filters by sync state', () async {
      await saveValue(); // pending at ou1
      expect(await store.orgUnitsWithWork(states: {SyncState.pending}), {ou1});
      expect(await store.orgUnitsWithWork(states: {SyncState.synced}), isEmpty);

      await store.markSynced((await store.pendingValues()).single);
      expect(await store.orgUnitsWithWork(states: {SyncState.synced}), {ou1});
      expect(
          await store.orgUnitsWithWork(states: {SyncState.pending}), isEmpty);
      expect(await store.orgUnitsWithWork(), {ou1},
          reason: 'no states = any state');
    });

    test('filters by last-modified window, end exclusive', () async {
      await saveValue(); // lastModified = now at ou1
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final yesterday = now.subtract(const Duration(days: 1));

      expect(await store.orgUnitsWithWork(from: yesterday, to: tomorrow),
          {ou1});
      expect(await store.orgUnitsWithWork(from: tomorrow), isEmpty);
      expect(await store.orgUnitsWithWork(to: yesterday), isEmpty);
    });

    test('sees completion-only org units too', () async {
      await db.into(db.completeDataSetRegistrationsTable).insert(
            CompleteDataSetRegistrationsTableCompanion.insert(
              dataSetUid: ds2,
              period: '201811',
              orgUnitUid: ou2,
              attributeOptionComboUid: coc,
              completed: true,
              date: DateTime.now(),
              syncState: SyncState.error,
              lastModified: DateTime.now(),
            ),
          );
      expect(await store.orgUnitsWithWork(states: {SyncState.error}), {ou2});
    });
  });

  group('countUnsyncedWork (wipe guard)', () {
    test('counts drafts, pending and error rows — everything a wipe '
        'would destroy', () async {
      expect(await countUnsyncedWork(db), 0);

      await saveValue(); // pending
      await store.setValue(
        dataElementUid: 'dataElem002',
        period: '201811',
        orgUnitUid: ou1,
        categoryOptionComboUid: coc,
        attributeOptionComboUid: coc,
        value: '7',
        draft: true,
      );
      expect(await countUnsyncedWork(db), 2);

      // Error rows are excluded from the clock-anchor gate but are
      // still the user's un-uploaded field data.
      final pending = await store.pendingValues();
      await store.markError(pending.single, 'rejected');
      expect(await countUnsyncedWork(db), 2);
      expect(await hasUnsyncedLocalData(db), isTrue,
          reason: 'the draft still blocks the anchor');

      await db.into(db.completeDataSetRegistrationsTable).insert(
            CompleteDataSetRegistrationsTableCompanion.insert(
              dataSetUid: ds1,
              period: '201811',
              orgUnitUid: ou1,
              attributeOptionComboUid: coc,
              completed: true,
              date: DateTime.now(),
              syncState: SyncState.pending,
              lastModified: DateTime.now(),
            ),
          );
      expect(await countUnsyncedWork(db), 3);
    });

    test('fully synced data counts nothing', () async {
      await saveValue();
      await store.markSynced((await store.pendingValues()).single);
      expect(await countUnsyncedWork(db), 0);
    });
  });

}

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/metadata/data_set.dart';

void main() {
  late AppDatabase db;

  const routineDs = 'routineDs01';
  const diseaseDs = 'diseaseDs01';
  const otherCategoryDs = 'plansetDs01';
  const uncategorisedDs = 'uncatDs0001';
  const ou1 = 'orgUnit0001';
  const coc = 'catOptCmb01';
  const categoryAttr = 'attribute01';

  Future<void> insertDataSet(String uid, String name) =>
      db.into(db.dataSetsTable).insert(DataSetsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: name,
            periodType: 'Monthly',
            categoryComboUid: coc,
          ));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.orgUnitsTable).insert(
          OrgUnitsTableCompanion.insert(
            uid: ou1,
            name: 'Health Post A',
            displayName: 'Health Post A',
            path: '/$ou1',
          ),
        );

    for (final uid in [
      routineDs,
      diseaseDs,
      otherCategoryDs,
      uncategorisedDs
    ]) {
      await insertDataSet(uid, uid);
      await db.into(db.dataSetOrgUnitsTable).insert(
            DataSetOrgUnitsTableCompanion.insert(
              dataSetUid: uid,
              orgUnitUid: ou1,
            ),
          );
    }

    await db.into(db.attributesTable).insert(
          AttributesTableCompanion.insert(
            uid: categoryAttr,
            name: 'Dataset Category',
            displayName: 'Dataset Category',
            valueType: 'TEXT',
          ),
        );
    Future<void> tag(String dsUid, String value) =>
        db.into(db.attributeValuesTable).insert(
              AttributeValuesTableCompanion.insert(
                objectType: 'dataSet',
                objectUid: dsUid,
                attributeUid: categoryAttr,
                value: value,
              ),
            );
    await tag(routineDs, 'Routine');
    await tag(diseaseDs, 'Disease');
    await tag(otherCategoryDs, 'Plan_Setting');
    // uncategorisedDs deliberately has no attribute value row.
  });

  tearDown(() async => db.close());

  group('DataSetResource.getByOrgUnit', () {
    test('returns every data set assigned to the org unit, disease included',
        () async {
      final rows = await DataSetResource(db).getByOrgUnit(ou1);
      final uids = {for (final r in rows) r.uid};

      expect(uids, {routineDs, diseaseDs, otherCategoryDs, uncategorisedDs},
          reason: 'Routine and Disease Registration data sets now share '
              'one merged capture flow');
    });
  });

  group('DataSetResource.diseaseRegistrationDataSetUids', () {
    test('returns only the data set tagged Disease', () async {
      final uids = await DataSetResource(db).diseaseRegistrationDataSetUids();
      expect(uids, {diseaseDs});
    });

    test('returns empty set when the attribute is not configured', () async {
      final freshDb = AppDatabase.forTesting(NativeDatabase.memory());
      final uids =
          await DataSetResource(freshDb).diseaseRegistrationDataSetUids();
      expect(uids, isEmpty);
      await freshDb.close();
    });
  });

  group('DataSetResource.categoryDimensions / resolveCategoryOptionCombo',
      () {
    const comboDs = 'comboDs0001';
    const comboUid = 'combo000001';
    const deptCat = 'deptCat0001';
    const outcomeCat = 'outcomeCat1';
    const opd = 'catOptOpd01';
    const ipd = 'catOptIpd01';
    const cured = 'catOptCure1';
    const died = 'catOptDied1';

    Future<void> setUpCombo() async {
      await db.into(db.dataSetsTable).insert(DataSetsTableCompanion.insert(
            uid: comboDs,
            name: comboDs,
            displayName: comboDs,
            periodType: 'Monthly',
            categoryComboUid: comboUid,
          ));
      await db.into(db.dataSetOrgUnitsTable).insert(
            DataSetOrgUnitsTableCompanion.insert(
                dataSetUid: comboDs, orgUnitUid: ou1),
          );

      await db.into(db.categoryCombosTable).insert(
            CategoryCombosTableCompanion.insert(
              uid: comboUid,
              name: 'Department x Outcome',
              displayName: 'Department x Outcome',
            ),
          );
      await db.into(db.categoriesTable).insert(CategoriesTableCompanion.insert(
          uid: deptCat, name: 'Department', displayName: 'Department'));
      await db.into(db.categoriesTable).insert(CategoriesTableCompanion.insert(
          uid: outcomeCat, name: 'Outcome', displayName: 'Outcome'));
      await db.batch((b) {
        b.insertAll(db.categoryComboCategoriesTable, [
          CategoryComboCategoriesTableCompanion.insert(
              categoryComboUid: comboUid, categoryUid: deptCat, sortOrder: const Value(0)),
          CategoryComboCategoriesTableCompanion.insert(
              categoryComboUid: comboUid, categoryUid: outcomeCat, sortOrder: const Value(1)),
        ]);
      });

      Future<void> option(String uid, String name) =>
          db.into(db.categoryOptionsTable).insert(
              CategoryOptionsTableCompanion.insert(
                  uid: uid, name: name, displayName: name));
      await option(opd, 'OPD');
      await option(ipd, 'IPD');
      await option(cured, 'Cured');
      await option(died, 'Died');
      await db.batch((b) {
        b.insertAll(db.categoryCategoryOptionsTable, [
          CategoryCategoryOptionsTableCompanion.insert(
              categoryUid: deptCat, categoryOptionUid: opd, sortOrder: const Value(0)),
          CategoryCategoryOptionsTableCompanion.insert(
              categoryUid: deptCat, categoryOptionUid: ipd, sortOrder: const Value(1)),
          CategoryCategoryOptionsTableCompanion.insert(
              categoryUid: outcomeCat, categoryOptionUid: cured, sortOrder: const Value(0)),
          CategoryCategoryOptionsTableCompanion.insert(
              categoryUid: outcomeCat, categoryOptionUid: died, sortOrder: const Value(1)),
        ]);
      });

      Future<void> coc(String uid, String name, List<String> opts) async {
        await db.into(db.categoryOptionCombosTable).insert(
            CategoryOptionCombosTableCompanion.insert(
                uid: uid, name: name, categoryComboUid: comboUid));
        await db.batch((b) {
          b.insertAll(db.categoryOptionComboOptionsTable, [
            for (final o in opts)
              CategoryOptionComboOptionsTableCompanion.insert(
                  categoryOptionComboUid: uid, categoryOptionUid: o),
          ]);
        });
      }

      await coc('cocOpdCure1', 'OPD, Cured', [opd, cured]);
      await coc('cocOpdDied1', 'OPD, Died', [opd, died]);
      await coc('cocIpdCure1', 'IPD, Cured', [ipd, cured]);
      await coc('cocIpdDied1', 'IPD, Died', [ipd, died]);
    }

    test('a default/trivial combo needs no dimensions', () async {
      final dims = await DataSetResource(db).categoryDimensions(routineDs);
      expect(dims, isEmpty);
    });

    test('a real combo returns its categories with their options', () async {
      await setUpCombo();
      final dims = await DataSetResource(db).categoryDimensions(comboDs);

      expect(dims, hasLength(2));
      expect(dims[0].name, 'Department');
      expect({for (final o in dims[0].options) o.name}, {'OPD', 'IPD'});
      expect(dims[1].name, 'Outcome');
      expect({for (final o in dims[1].options) o.name}, {'Cured', 'Died'});
    });

    test('resolveCategoryOptionCombo finds the exact combo', () async {
      await setUpCombo();
      final resolved = await DataSetResource(db)
          .resolveCategoryOptionCombo(comboDs, {deptCat: ipd, outcomeCat: died});
      expect(resolved, 'cocIpdDied1');
    });

    test('resolveCategoryOptionCombo returns null for an incomplete selection',
        () async {
      await setUpCombo();
      final resolved = await DataSetResource(db)
          .resolveCategoryOptionCombo(comboDs, {deptCat: ipd});
      expect(resolved, isNull);
    });

    test(
        'a combo named default needs no dimensions even with duplicate COCs '
        'synced under it', () async {
      // Reproduces the HMIS staging data-integrity defect: multiple
      // categoryOptionCombos named 'default' all synced under the SAME
      // categoryCombo (also named 'default'). Without the name check,
      // cocs.length > 1 would wrongly make this look like a real
      // disaggregation and prompt the user to "pick a combination".
      const dupeComboDs = 'dupComboDs1';
      const dupeComboUid = 'dupCombo001';
      await db.into(db.dataSetsTable).insert(DataSetsTableCompanion.insert(
            uid: dupeComboDs,
            name: dupeComboDs,
            displayName: dupeComboDs,
            periodType: 'Monthly',
            categoryComboUid: dupeComboUid,
          ));
      await db.into(db.categoryCombosTable).insert(
            CategoryCombosTableCompanion.insert(
              uid: dupeComboUid,
              name: 'default',
              displayName: 'default',
            ),
          );
      await db.batch((b) {
        b.insertAll(db.categoryOptionCombosTable, [
          CategoryOptionCombosTableCompanion.insert(
              uid: 'ed678csgTm8', name: 'default', categoryComboUid: dupeComboUid),
          CategoryOptionCombosTableCompanion.insert(
              uid: 'HllvX50cXC0', name: 'default', categoryComboUid: dupeComboUid),
        ]);
      });

      final dims = await DataSetResource(db).categoryDimensions(dupeComboDs);
      expect(dims, isEmpty);
    });
  });
}

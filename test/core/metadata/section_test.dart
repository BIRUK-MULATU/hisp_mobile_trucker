import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/metadata/section.dart';

void main() {
  late AppDatabase db;

  const dataSetUid = 'dataSet0001';
  const sectionA = 'sectionAAA1';
  const sectionB = 'sectionBBB1';
  const deDisease = 'deDisease01'; // "ESV-ICD11 ... Cervical..."
  const cocMale = 'cocMaleXXX1';
  const cocFemale = 'cocFemaleX1';

  Future<void> insertSection(String uid, {int sortOrder = 0}) =>
      db.into(db.sectionsTable).insert(
            SectionsTableCompanion.insert(
              uid: uid,
              name: uid,
              displayName: uid,
              dataSetUid: dataSetUid,
              sortOrder: Value(sortOrder),
            ),
          );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await insertSection(sectionA);
    await insertSection(sectionB, sortOrder: 1);
    await db.into(db.sectionGreyFieldsTable).insert(
          SectionGreyFieldsTableCompanion.insert(
            sectionUid: sectionA,
            dataElementUid: deDisease,
            categoryOptionComboUid: cocMale,
          ),
        );
    await db.into(db.sectionGreyFieldsTable).insert(
          SectionGreyFieldsTableCompanion.insert(
            sectionUid: sectionB,
            dataElementUid: deDisease,
            categoryOptionComboUid: cocFemale,
          ),
        );
  });

  tearDown(() => db.close());

  group('SectionResource', () {
    test('greyFieldsOf returns only the requested section\'s pairs', () async {
      final rows = await SectionResource(db).greyFieldsOf(sectionA);
      expect(rows, hasLength(1));
      expect(rows.first.dataElementUid, deDisease);
      expect(rows.first.categoryOptionComboUid, cocMale);
    });

    test('greyFieldsForDataSet unions every section of the data set', () async {
      final rows = await SectionResource(db).greyFieldsForDataSet(dataSetUid);
      final combos = {for (final r in rows) r.categoryOptionComboUid};
      expect(combos, {cocMale, cocFemale});
    });

    test('greyFieldsForDataSet is empty for a data set with no sections',
        () async {
      final rows =
          await SectionResource(db).greyFieldsForDataSet('otherDtSet1');
      expect(rows, isEmpty);
    });
  });
}

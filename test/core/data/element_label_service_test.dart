import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/element_label_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const groupAttr = 'lblGrpAttr1';
  const optionSetAttr = 'lblSetAttr1';
  const labelOptionSet = 'lblOptSet01';
  const prlafpDe = 'prlafpDe001'; // "MAT_LAFP Removal within 6..."
  const sharedDeA = 'sharedDeA01';
  const sharedDeB = 'sharedDeB01';
  const plainDe = 'plainDe0001';

  Future<void> insertDataElement(String uid) =>
      db.into(db.dataElementsTable).insert(
            DataElementsTableCompanion.insert(
              uid: uid,
              name: uid,
              displayName: uid,
              formName: uid,
              valueType: 'INTEGER_ZERO_OR_POSITIVE',
              categoryComboUid: 'catCombo001',
            ),
          );

  Future<void> tagLabelGroup(String deUid, String code) =>
      db.into(db.attributeValuesTable).insert(
            AttributeValuesTableCompanion.insert(
              objectType: 'dataElement',
              objectUid: deUid,
              attributeUid: groupAttr,
              value: code,
            ),
          );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.attributesTable).insert(
          AttributesTableCompanion.insert(
            uid: groupAttr,
            name: 'Label Data Element Groups',
            displayName: 'Label Data Element Groups',
            valueType: 'TEXT',
          ),
        );
    await db.into(db.attributesTable).insert(
          AttributesTableCompanion.insert(
            uid: optionSetAttr,
            name: 'Label Option Set',
            displayName: 'Label Option Set',
            valueType: 'BOOLEAN',
          ),
        );

    await db.into(db.optionSetsTable).insert(
          OptionSetsTableCompanion.insert(
            uid: labelOptionSet,
            name: 'Data element Group Label',
            displayName: 'Data element Group Label',
            valueType: 'TEXT',
          ),
        );
    await db.into(db.attributeValuesTable).insert(
          AttributeValuesTableCompanion.insert(
            objectType: 'optionSet',
            objectUid: labelOptionSet,
            attributeUid: optionSetAttr,
            value: 'true',
          ),
        );
    await db.into(db.optionsTable).insert(
          OptionsTableCompanion.insert(
            uid: 'optPrlafp01',
            code: 'RMH_FP_LAFPPR',
            name: 'Premature Removal of Long term family planning methods '
                '(PRLAFP)',
            displayName: 'Premature Removal of Long term family planning '
                'methods (PRLAFP)',
            optionSetUid: labelOptionSet,
          ),
        );
    await db.into(db.optionsTable).insert(
          OptionsTableCompanion.insert(
            uid: 'optShared01',
            code: 'HR_STANDARD',
            name: 'Health Facility staffed as per the standard',
            displayName: 'Health Facility staffed as per the standard',
            optionSetUid: labelOptionSet,
          ),
        );

    for (final uid in [prlafpDe, sharedDeA, sharedDeB, plainDe]) {
      await insertDataElement(uid);
    }
    await tagLabelGroup(prlafpDe, 'RMH_FP_LAFPPR');
    await tagLabelGroup(sharedDeA, 'HR_STANDARD');
    await tagLabelGroup(sharedDeB, 'HR_STANDARD');
    // plainDe deliberately carries no label.
  });

  tearDown(() => db.close());

  group('ElementLabelService.labelsFor', () {
    test('resolves a label code to the option set\'s display name', () async {
      final labels = await ElementLabelService(db)
          .labelsFor([prlafpDe, sharedDeA, sharedDeB, plainDe]);

      expect(labels[prlafpDe],
          'Premature Removal of Long term family planning methods (PRLAFP)');
    });

    test('two elements sharing one code resolve to the same label', () async {
      final labels = await ElementLabelService(db)
          .labelsFor([prlafpDe, sharedDeA, sharedDeB, plainDe]);

      expect(labels[sharedDeA], labels[sharedDeB]);
      expect(labels[sharedDeA], 'Health Facility staffed as per the standard');
    });

    test('an element with no label attribute is left out entirely', () async {
      final labels = await ElementLabelService(db).labelsFor([plainDe]);
      expect(labels, isEmpty);
    });

    test(
        'missing "Label Option Set" flag (no vocabulary) resolves '
        'nothing', () async {
      await (db.delete(db.attributeValuesTable)
            ..where((t) =>
                t.objectType.equals('optionSet') &
                t.attributeUid.equals(optionSetAttr)))
          .go();
      final labels = await ElementLabelService(db).labelsFor([prlafpDe]);
      expect(labels, isEmpty);
    });

    test(
        'a code with no matching option resolves nothing for that '
        'element', () async {
      const strayDe = 'strayDe0001';
      await insertDataElement(strayDe);
      await tagLabelGroup(strayDe, 'NO_SUCH_CODE');

      final labels = await ElementLabelService(db).labelsFor([strayDe]);
      expect(labels, isEmpty);
    });
  });
}

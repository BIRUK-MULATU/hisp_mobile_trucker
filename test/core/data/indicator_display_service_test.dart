import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/indicator_display_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const displayableAttr = 'dispIndAtr1';
  const newAcceptors = 'newAccept01'; // "...New Acceptors By Age"
  const repeatAcceptors = 'repeatAcc01'; // "...Repeat Acceptors By Age"
  const otherElement = 'otherElem01'; // present in the form, unrelated
  const carAgeInd = 'carAgeInd01'; // "MAT_New and Repeat..." indicator

  Future<void> flagDisplayable(String indicatorUid) =>
      db.into(db.attributeValuesTable).insert(
            AttributeValuesTableCompanion.insert(
              objectType: 'indicator',
              objectUid: indicatorUid,
              attributeUid: displayableAttr,
              value: 'true',
            ),
          );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.attributesTable).insert(
          AttributesTableCompanion.insert(
            uid: displayableAttr,
            name: 'Indicator displayable',
            displayName: 'Indicator displayable',
            valueType: 'BOOLEAN',
          ),
        );

    await db.into(db.indicatorsTable).insert(
          IndicatorsTableCompanion.insert(
            uid: carAgeInd,
            name: 'MAT_New and Repeat Contraceptive Acceptors by Age',
            displayName: 'MAT_New and Repeat Contraceptive Acceptors by Age',
            numerator: '#{$newAcceptors} + #{$repeatAcceptors}',
            denominator: '1',
            indicatorTypeFactor: const Value(1),
          ),
        );
  });

  tearDown(() => db.close());

  group('IndicatorDisplayService.displayIndicatorsFor', () {
    test('anchors to the FIRST referenced element in form order', () async {
      await flagDisplayable(carAgeInd);

      final gates = await IndicatorDisplayService(db)
          .displayIndicatorsFor([otherElement, newAcceptors, repeatAcceptors]);

      expect(gates.keys, [newAcceptors]);
      expect(gates[newAcceptors], hasLength(1));
      expect(gates[newAcceptors]!.first.name,
          'MAT_New and Repeat Contraceptive Acceptors by Age');
      expect(gates[newAcceptors]!.first.numerator,
          '#{$newAcceptors} + #{$repeatAcceptors}');
    });

    test(
        'anchors to whichever referenced element appears first, even '
        'if that is the SECOND operand in the formula', () async {
      await flagDisplayable(carAgeInd);

      // repeatAcceptors comes before newAcceptors in THIS form.
      final gates = await IndicatorDisplayService(db)
          .displayIndicatorsFor([repeatAcceptors, newAcceptors]);

      expect(gates.keys, [repeatAcceptors]);
    });

    test(
        'an indicator with none of its operands in the form is left '
        'out entirely', () async {
      await flagDisplayable(carAgeInd);

      final gates = await IndicatorDisplayService(db)
          .displayIndicatorsFor([otherElement]);
      expect(gates, isEmpty);
    });

    test('a non-displayable indicator (no flag) is never returned', () async {
      final gates = await IndicatorDisplayService(db)
          .displayIndicatorsFor([newAcceptors, repeatAcceptors]);
      expect(gates, isEmpty);
    });

    test(
        'missing "Indicator displayable" attribute definition returns '
        'nothing', () async {
      await (db.delete(db.attributesTable)
            ..where((t) => t.uid.equals(displayableAttr)))
          .go();
      final gates = await IndicatorDisplayService(db)
          .displayIndicatorsFor([newAcceptors, repeatAcceptors]);
      expect(gates, isEmpty);
    });
  });
}

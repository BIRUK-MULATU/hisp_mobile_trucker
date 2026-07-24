import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/validation_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  group('ExpressionEvaluator', () {
    double? lookup(String de, String? coc) {
      const values = {
        'dataElem001.catOptCmb01': 10.0,
        'dataElem001.catOptCmb02': 5.0,
        'dataElem002.catOptCmb01': 3.0,
      };
      if (coc != null) return values['$de.$coc'];
      // element total
      double? total;
      for (final e in values.entries) {
        if (e.key.startsWith('$de.')) total = (total ?? 0) + e.value;
      }
      return total;
    }

    test('operand with coc, arithmetic and parentheses', () {
      final e = ExpressionEvaluator(
          '#{dataElem001.catOptCmb01} + 2 * (#{dataElem002.catOptCmb01} - 1)',
          lookup);
      expect(e.evaluate(), 14.0);
      expect(e.operands, 2);
      expect(e.present, 2);
    });

    test('operand without coc sums the element total', () {
      final e = ExpressionEvaluator('#{dataElem001}', lookup);
      expect(e.evaluate(), 15.0);
    });

    test('missing operand counts as 0 and tracked as absent', () {
      final e = ExpressionEvaluator(
          '#{dataElem001.catOptCmb01} + #{dataElem009.catOptCmb01}', lookup);
      expect(e.evaluate(), 10.0);
      expect(e.operands, 2);
      expect(e.present, 1);
    });

    test('unsupported syntax throws instead of guessing', () {
      expect(() => ExpressionEvaluator('if(1,2,3)', lookup).evaluate(),
          throwsA(isA<UnsupportedExpression>()));
      expect(() => ExpressionEvaluator('C{constant0001}', lookup).evaluate(),
          throwsA(isA<UnsupportedExpression>()));
      expect(() => ExpressionEvaluator('[days]', lookup).evaluate(),
          throwsA(isA<UnsupportedExpression>()));
    });
  });

  group('ValidationService.validateForm', () {
    late AppDatabase db;

    const ds = 'dataSet0001';
    const de1 = 'dataElem001';
    const de2 = 'dataElem002';
    const ou = 'orgUnit0001';
    const coc = 'catOptCmb01';
    const aoc = 'catOptCmb01';
    const period = '202506';

    Future<void> seedRule({
      required String uid,
      required String operator,
      required String left,
      required String right,
      String? leftStrategy,
      String? rightStrategy,
    }) {
      return db.into(db.validationRulesTable).insert(
            ValidationRulesTableCompanion.insert(
              uid: uid,
              name: uid,
              displayName: 'Rule $uid',
              operator: operator,
              leftExpression: left,
              rightExpression: right,
              leftMissingValueStrategy: Value(leftStrategy),
              rightMissingValueStrategy: Value(rightStrategy),
            ),
          );
    }

    Future<void> seedValue(String de, String value) {
      return db.into(db.dataValuesTable).insert(
            DataValuesTableCompanion.insert(
              dataElementUid: de,
              period: period,
              orgUnitUid: ou,
              categoryOptionComboUid: coc,
              attributeOptionComboUid: aoc,
              value: Value(value),
              syncState: SyncState.draft,
              lastModified: DateTime(2026, 7, 22),
            ),
          );
    }

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.into(db.dataSetsTable).insert(
            DataSetsTableCompanion.insert(
              uid: ds,
              name: 'DS',
              displayName: 'DS',
              periodType: 'Monthly',
              categoryComboUid: 'catCombo001',
            ),
          );
      for (final de in [de1, de2]) {
        await db.into(db.dataSetElementsTable).insert(
              DataSetElementsTableCompanion.insert(
                dataSetUid: ds,
                dataElementUid: de,
                categoryComboUid: 'catCombo001',
              ),
            );
      }
    });

    tearDown(() => db.close());

    Future<List<ValidationViolation>> run() =>
        ValidationService(db).validateForm(
          dataSetUid: ds,
          period: period,
          orgUnitUid: ou,
          attributeOptionComboUid: aoc,
        );

    test('violated less_than_or_equal_to rule is reported', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'less_than_or_equal_to',
          left: '#{$de1.$coc}',
          right: '#{$de2.$coc}');
      await seedValue(de1, '12');
      await seedValue(de2, '10');

      final v = await run();
      expect(v, hasLength(1));
      expect(v.first.leftValue, 12);
      expect(v.first.rightValue, 10);
    });

    test('satisfied rule reports nothing', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'less_than_or_equal_to',
          left: '#{$de1.$coc}',
          right: '#{$de2.$coc}');
      await seedValue(de1, '8');
      await seedValue(de2, '10');

      expect(await run(), isEmpty);
    });

    test('default strategy skips a side with all values missing',
        () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'less_than_or_equal_to',
          left: '#{$de1.$coc}',
          right: '#{$de2.$coc}');
      await seedValue(de2, '10'); // left side has no data at all

      expect(await run(), isEmpty);
    });

    test('NEVER_SKIP evaluates a missing side as 0', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'greater_than',
          left: '#{$de1.$coc}',
          right: '#{$de2.$coc}',
          leftStrategy: 'NEVER_SKIP',
          rightStrategy: 'NEVER_SKIP');
      await seedValue(de2, '10'); // left missing -> 0 > 10 is false

      final v = await run();
      expect(v, hasLength(1)); // violated: 0 is not > 10
    });

    test('compulsory_pair flags one-sided data', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'compulsory_pair',
          left: '#{$de1.$coc}',
          right: '#{$de2.$coc}');
      await seedValue(de1, '4');

      expect(await run(), hasLength(1));
    });

    test('rules about other data sets are ignored', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'equal_to',
          left: '#{dataElem888.$coc}',
          right: '#{dataElem999.$coc}');

      expect(await run(), isEmpty);
    });

    test('unsupported expression is skipped, not guessed', () async {
      await seedRule(
          uid: 'valRule0001',
          operator: 'equal_to',
          left: 'if(#{$de1.$coc}>0,1,0)',
          right: '#{$de2.$coc}');
      await seedValue(de1, '5');
      await seedValue(de2, '10');

      expect(await run(), isEmpty);
    });
  });
}

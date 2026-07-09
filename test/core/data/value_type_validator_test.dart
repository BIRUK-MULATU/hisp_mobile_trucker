import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/value_type_validator.dart';

void main() {
  test('empty is always valid — it clears the cell', () {
    for (final t in ['NUMBER', 'INTEGER_POSITIVE', 'BOOLEAN', 'TEXT']) {
      expect(validateDataValue(t, ''), isNull);
      expect(validateDataValue(t, '   '), isNull);
    }
  });

  test('NUMBER accepts decimals, rejects malformed input', () {
    expect(validateDataValue('NUMBER', '12.5'), isNull);
    expect(validateDataValue('NUMBER', '-3'), isNull);
    expect(validateDataValue('NUMBER', '1.2.3'), isNotNull);
    expect(validateDataValue('NUMBER', '-'), isNotNull);
    expect(validateDataValue('NUMBER', '5-3'), isNotNull);
  });

  test('INTEGER family enforces sign constraints', () {
    expect(validateDataValue('INTEGER', '-7'), isNull);
    expect(validateDataValue('INTEGER', '7.5'), isNotNull);
    expect(validateDataValue('INTEGER_POSITIVE', '1'), isNull);
    expect(validateDataValue('INTEGER_POSITIVE', '0'), isNotNull);
    expect(validateDataValue('INTEGER_NEGATIVE', '-1'), isNull);
    expect(validateDataValue('INTEGER_NEGATIVE', '0'), isNotNull);
    expect(validateDataValue('INTEGER_ZERO_OR_POSITIVE', '0'), isNull);
    expect(validateDataValue('INTEGER_ZERO_OR_POSITIVE', '-1'), isNotNull);
  });

  test('PERCENTAGE and UNIT_INTERVAL enforce their ranges', () {
    expect(validateDataValue('PERCENTAGE', '100'), isNull);
    expect(validateDataValue('PERCENTAGE', '101'), isNotNull);
    expect(validateDataValue('UNIT_INTERVAL', '0.4'), isNull);
    expect(validateDataValue('UNIT_INTERVAL', '1.4'), isNotNull);
  });

  test('BOOLEAN and TRUE_ONLY only accept their literals', () {
    expect(validateDataValue('BOOLEAN', 'true'), isNull);
    expect(validateDataValue('BOOLEAN', 'yes'), isNotNull);
    expect(validateDataValue('TRUE_ONLY', 'true'), isNull);
    expect(validateDataValue('TRUE_ONLY', 'false'), isNotNull);
  });

  test('unknown types never block entry', () {
    expect(validateDataValue('FILE_RESOURCE', 'whatever'), isNull);
    expect(validateDataValue('TEXT', 'free text!'), isNull);
  });
}

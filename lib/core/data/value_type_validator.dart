/// Client-side validation of a data value against its element's DHIS2
/// valueType — the same checks the server runs on import (E7619 etc.),
/// applied BEFORE a value is queued so garbage never leaves the device.
///
/// Returns a short user-readable problem, or null when the value is
/// acceptable. The empty string is always valid: it clears the cell.
String? validateDataValue(String valueType, String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  switch (valueType.toUpperCase()) {
    case 'NUMBER':
      if (double.tryParse(v) == null) return 'Not a valid number';
      return null;

    case 'INTEGER':
      if (int.tryParse(v) == null) return 'Not a whole number';
      return null;

    case 'INTEGER_POSITIVE':
      final n = int.tryParse(v);
      if (n == null) return 'Not a whole number';
      if (n <= 0) return 'Must be greater than zero';
      return null;

    case 'INTEGER_NEGATIVE':
      final n = int.tryParse(v);
      if (n == null) return 'Not a whole number';
      if (n >= 0) return 'Must be less than zero';
      return null;

    case 'INTEGER_ZERO_OR_POSITIVE':
      final n = int.tryParse(v);
      if (n == null) return 'Not a whole number';
      if (n < 0) return 'Cannot be negative';
      return null;

    case 'PERCENTAGE':
      final n = double.tryParse(v);
      if (n == null) return 'Not a valid number';
      if (n < 0 || n > 100) return 'Must be between 0 and 100';
      return null;

    case 'UNIT_INTERVAL':
      final n = double.tryParse(v);
      if (n == null) return 'Not a valid number';
      if (n < 0 || n > 1) return 'Must be between 0 and 1';
      return null;

    case 'BOOLEAN':
      if (v != 'true' && v != 'false') return 'Must be Yes or No';
      return null;

    case 'TRUE_ONLY':
      if (v != 'true') return 'Can only be ticked or empty';
      return null;

    case 'DATE':
      if (DateTime.tryParse(v) == null) return 'Not a valid date';
      return null;

    case 'PHONE_NUMBER':
      if (!RegExp(r'^\+?[0-9 \-()]{4,}$').hasMatch(v)) {
        return 'Not a valid phone number';
      }
      return null;

    case 'EMAIL':
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
        return 'Not a valid email address';
      }
      return null;

    // TEXT, LONG_TEXT, and anything unknown: accept as-is. Unknown
    // types must never block entry — the server stays the authority.
    default:
      return null;
  }
}

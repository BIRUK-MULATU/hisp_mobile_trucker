import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/app_logger.dart';

/// One failed validation rule check for a form instance — what the
/// completion flow shows the user. Violations WARN, they never block:
/// same contract as the DHIS2 web and Android apps.
class ValidationViolation {
  const ValidationViolation({
    required this.ruleName,
    required this.operator,
    this.instruction,
    this.importance,
    this.leftValue,
    this.rightValue,
    this.leftDescription,
    this.rightDescription,
  });

  final String ruleName;

  /// DHIS2 operator token (equal_to, greater_than, compulsory_pair, ...).
  final String operator;

  /// The rule author's "what to do about it" text, when present.
  final String? instruction;

  /// HIGH / MEDIUM / LOW.
  final String? importance;

  /// Evaluated side values — null for the pair operators, where only
  /// presence matters.
  final double? leftValue;
  final double? rightValue;
  final String? leftDescription;
  final String? rightDescription;

  /// Human line for the two sides, e.g. "ANC 1st visit (12) should be
  /// ≤ ANC follow-up (10)".
  String get detail {
    final l = leftDescription ?? 'Left side';
    final r = rightDescription ?? 'Right side';
    switch (operator) {
      case 'compulsory_pair':
        return '$l and $r must be filled together';
      case 'exclusive_pair':
        return '$l and $r must not both be filled';
      default:
        return '$l (${_fmt(leftValue)}) should be ${_symbol(operator)} '
            '$r (${_fmt(rightValue)})';
    }
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  static String _symbol(String op) => switch (op) {
        'equal_to' => '=',
        'not_equal_to' => '≠',
        'greater_than' => '>',
        'greater_than_or_equal_to' => '≥',
        'less_than' => '<',
        'less_than_or_equal_to' => '≤',
        _ => op,
      };
}

/// Thrown by [ExpressionEvaluator] for expression features the offline
/// engine does not implement (d2 functions, constants, org unit
/// groups, ...) — the rule is then SKIPPED, never guessed at.
class UnsupportedExpression implements Exception {
  UnsupportedExpression(this.what);
  final String what;
  @override
  String toString() => 'UnsupportedExpression: $what';
}

/// Evaluates one validation-rule side: arithmetic over data element
/// operands `#{deUid}` / `#{deUid.cocUid}`, numbers and parentheses.
///
/// This is deliberately the SAME subset the DHIS2 Android SDK
/// evaluates offline; anything beyond it (if(), constants C{...},
/// indicators, [days], ...) throws [UnsupportedExpression] so the
/// caller can skip the rule instead of producing a wrong verdict.
class ExpressionEvaluator {
  ExpressionEvaluator(this.expression, this.lookup);

  final String expression;

  /// Operand resolver: value of `#{de}` (coc == null means the
  /// element TOTAL across its combos) or null when no value exists.
  final double? Function(String de, String? coc) lookup;

  int _pos = 0;
  int operands = 0;
  int present = 0;

  /// Evaluates the whole expression. Missing operands contribute 0 —
  /// whether that renders the result meaningless is the caller's call
  /// via [operands]/[present] and the side's missingValueStrategy.
  double evaluate() {
    final v = _expr();
    _skipWs();
    if (_pos != expression.length) {
      throw UnsupportedExpression(
          'trailing "${expression.substring(_pos)}"');
    }
    return v;
  }

  double _expr() {
    var v = _term();
    while (true) {
      _skipWs();
      if (_peek() == '+') {
        _pos++;
        v += _term();
      } else if (_peek() == '-') {
        _pos++;
        v -= _term();
      } else {
        return v;
      }
    }
  }

  double _term() {
    var v = _factor();
    while (true) {
      _skipWs();
      if (_peek() == '*') {
        _pos++;
        v *= _factor();
      } else if (_peek() == '/') {
        _pos++;
        v /= _factor();
      } else {
        return v;
      }
    }
  }

  double _factor() {
    _skipWs();
    final c = _peek();
    if (c == '(') {
      _pos++;
      final v = _expr();
      _skipWs();
      if (_peek() != ')') throw UnsupportedExpression('missing )');
      _pos++;
      return v;
    }
    if (c == '-') {
      _pos++;
      return -_factor();
    }
    if (c == '#') return _operand();
    if (c != null && (_isDigit(c) || c == '.')) return _number();
    throw UnsupportedExpression('at "${expression.substring(_pos)}"');
  }

  double _operand() {
    // #{deUid} or #{deUid.cocUid}
    if (!expression.startsWith('#{', _pos)) {
      throw UnsupportedExpression('malformed operand');
    }
    final end = expression.indexOf('}', _pos);
    if (end < 0) throw UnsupportedExpression('unterminated operand');
    final body = expression.substring(_pos + 2, end);
    _pos = end + 1;
    final parts = body.split('.');
    if (parts.isEmpty || parts.length > 2 || parts[0].length != 11) {
      throw UnsupportedExpression('operand "$body"');
    }
    // A second dimension beyond the coc (de.coc.aoc form) is rare and
    // unsupported — bail rather than misread it.
    final coc = parts.length == 2 ? parts[1] : null;
    if (coc != null && (coc.length != 11 && coc != '*')) {
      throw UnsupportedExpression('operand "$body"');
    }
    operands++;
    final v = lookup(parts[0], coc == '*' ? null : coc);
    if (v == null) return 0;
    present++;
    return v;
  }

  double _number() {
    final start = _pos;
    while (_pos < expression.length &&
        (_isDigit(expression[_pos]) || expression[_pos] == '.')) {
      _pos++;
    }
    final v = double.tryParse(expression.substring(start, _pos));
    if (v == null) throw UnsupportedExpression('bad number');
    return v;
  }

  String? _peek() => _pos < expression.length ? expression[_pos] : null;

  void _skipWs() {
    while (_pos < expression.length && expression[_pos] == ' ') {
      _pos++;
    }
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
}

/// Runs the synced validation rules against ONE form instance's local
/// values — fully offline, on the same data the user sees in the form.
class ValidationService {
  ValidationService(this._db);

  final AppDatabase _db;

  /// Rules considered: periodType matches the data set's (or unset)
  /// AND at least one operand is an element of this data set. Rules
  /// with unsupported expression features or whose missing-value
  /// strategy says skip are silently left out — informative checks
  /// must not invent violations from data they can't read.
  Future<List<ValidationViolation>> validateForm({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
  }) async {
    final ds = await (_db.select(_db.dataSetsTable)
          ..where((t) => t.uid.equals(dataSetUid)))
        .getSingleOrNull();
    final elementRows = await (_db.select(_db.dataSetElementsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid)))
        .get();
    final formElements = {for (final r in elementRows) r.dataElementUid};
    if (formElements.isEmpty) return const [];

    // ALL local values of this period/orgUnit/aoc — a rule may relate
    // a form element to one outside the data set; local data for it
    // still counts (missing-value strategies handle true gaps).
    final valueRows = await (_db.select(_db.dataValuesTable)
          ..where((t) =>
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid)))
        .get();
    final byOperand = <String, double>{};
    final totals = <String, double>{};
    for (final r in valueRows) {
      final v = _numeric(r.value);
      if (v == null) continue;
      byOperand['${r.dataElementUid}.${r.categoryOptionComboUid}'] = v;
      totals[r.dataElementUid] = (totals[r.dataElementUid] ?? 0) + v;
    }
    double? lookup(String de, String? coc) =>
        coc == null ? totals[de] : byOperand['$de.$coc'];

    final rules = await _db.select(_db.validationRulesTable).get();
    final violations = <ValidationViolation>[];
    var skipped = 0;
    for (final rule in rules) {
      if (rule.periodType != null &&
          ds != null &&
          rule.periodType != ds.periodType) {
        continue;
      }
      // Only rules that touch this form at all.
      if (!_referencedElements(rule).any(formElements.contains)) continue;
      try {
        final left = ExpressionEvaluator(rule.leftExpression, lookup);
        final leftValue = left.evaluate();
        final right = ExpressionEvaluator(rule.rightExpression, lookup);
        final rightValue = right.evaluate();

        final violated = _check(
          rule.operator,
          leftValue: leftValue,
          rightValue: rightValue,
          leftPresent: left.present,
          rightPresent: right.present,
          leftSkips: _skips(rule.leftMissingValueStrategy, left),
          rightSkips: _skips(rule.rightMissingValueStrategy, right),
        );
        if (violated == null) {
          skipped++;
        } else if (violated) {
          violations.add(ValidationViolation(
            ruleName: rule.displayName,
            operator: rule.operator,
            instruction: rule.instruction ?? rule.description,
            importance: rule.importance,
            leftValue: leftValue,
            rightValue: rightValue,
            leftDescription: rule.leftDescription,
            rightDescription: rule.rightDescription,
          ));
        }
      } on UnsupportedExpression {
        skipped++;
      }
    }
    log.i('[validation] $dataSetUid/$period/$orgUnitUid: '
        '${violations.length} violation(s), $skipped rule(s) skipped');
    return violations;
  }

  static final _operandRe = RegExp(r'#\{([A-Za-z0-9]{11})');

  List<String> _referencedElements(ValidationRule rule) => [
        for (final m in _operandRe
            .allMatches('${rule.leftExpression} ${rule.rightExpression}'))
          m.group(1)!,
      ];

  bool _skips(String? strategy, ExpressionEvaluator side) {
    switch (strategy) {
      case 'NEVER_SKIP':
        return false;
      case 'SKIP_IF_ANY_VALUE_MISSING':
        return side.present < side.operands;
      default: // SKIP_IF_ALL_VALUES_MISSING — the DHIS2 default
        return side.operands > 0 && side.present == 0;
    }
  }

  /// true = violated, false = passed, null = not judgeable (skip).
  bool? _check(
    String operator, {
    required double leftValue,
    required double rightValue,
    required int leftPresent,
    required int rightPresent,
    required bool leftSkips,
    required bool rightSkips,
  }) {
    // Pair operators are about PRESENCE, not arithmetic — the
    // missing-value strategies don't apply to them.
    if (operator == 'compulsory_pair') {
      return (leftPresent > 0) != (rightPresent > 0);
    }
    if (operator == 'exclusive_pair') {
      return leftPresent > 0 && rightPresent > 0;
    }

    if (leftSkips || rightSkips) return null;
    if (!leftValue.isFinite || !rightValue.isFinite) return null;

    const eps = 1e-6;
    return switch (operator) {
      'equal_to' => (leftValue - rightValue).abs() > eps,
      'not_equal_to' => (leftValue - rightValue).abs() <= eps,
      'greater_than' => leftValue <= rightValue,
      'greater_than_or_equal_to' => leftValue < rightValue,
      'less_than' => leftValue >= rightValue,
      'less_than_or_equal_to' => leftValue > rightValue,
      _ => null, // unknown operator: don't guess
    };
  }

  static double? _numeric(String? raw) {
    if (raw == null) return null;
    if (raw == 'true') return 1;
    if (raw == 'false') return 0;
    return double.tryParse(raw);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/shared/widgets/filter_panel.dart';

void main() {
  // A Wednesday, so week boundaries are non-trivial.
  final now = DateTime(2026, 7, 15, 14, 30);

  DateTimeRange? resolve(String label) =>
      resolveDateFilter(AppliedFilter(label), now);

  test('single-day options span exactly that day', () {
    expect(resolve('Today'),
        DateTimeRange(start: DateTime(2026, 7, 15), end: DateTime(2026, 7, 16)));
    expect(resolve('Yesterday'),
        DateTimeRange(start: DateTime(2026, 7, 14), end: DateTime(2026, 7, 15)));
    expect(resolve('Tomorrow'),
        DateTimeRange(start: DateTime(2026, 7, 16), end: DateTime(2026, 7, 17)));
  });

  test('weeks are Monday-based', () {
    expect(resolve('This Week'),
        DateTimeRange(start: DateTime(2026, 7, 13), end: DateTime(2026, 7, 20)));
    expect(resolve('Last Week'),
        DateTimeRange(start: DateTime(2026, 7, 6), end: DateTime(2026, 7, 13)));
    expect(resolve('Next week'),
        DateTimeRange(start: DateTime(2026, 7, 20), end: DateTime(2026, 7, 27)));
  });

  test('months roll over the year boundary', () {
    final december = DateTime(2026, 12, 5);
    expect(
        resolveDateFilter(const AppliedFilter('Next month'), december),
        DateTimeRange(start: DateTime(2027, 1, 1), end: DateTime(2027, 2, 1)));
    final january = DateTime(2026, 1, 5);
    expect(
        resolveDateFilter(const AppliedFilter('Last month'), january),
        DateTimeRange(start: DateTime(2025, 12, 1), end: DateTime(2026, 1, 1)));
  });

  test('Any time means no restriction', () {
    expect(resolve('Any time'), isNull);
  });

  test('a custom range wins over the label', () {
    final range =
        DateTimeRange(start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 8));
    expect(
        resolveDateFilter(AppliedFilter('01/05/2026 - 07/05/2026', range: range),
            now),
        range);
  });
}

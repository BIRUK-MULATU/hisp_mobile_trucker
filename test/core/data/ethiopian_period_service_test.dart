import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/ethiopian_calendar.dart';
import 'package:hisp_mobile_trucker/core/data/ethiopian_period_service.dart';
import 'package:hisp_mobile_trucker/core/data/period_access.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  DataSet dataSet(String periodType, {int expiryDays = 30}) => DataSet(
        uid: 'ds1',
        name: 'test',
        displayName: 'test',
        periodType: periodType,
        version: 1,
        categoryComboUid: 'cc1',
        openFuturePeriods: 0,
        expiryDays: expiryDays,
      );

  test('current monthly period is open, old ones expired (expiryDays=30)',
      () async {
    final periods = await EthiopianPeriodService(db)
        .periodsFor(dataSet: dataSet('Monthly'), count: 12);

    expect(periods.first.isOpen, isTrue,
        reason: 'the current Ethiopian month must be enterable, '
            'got ${periods.first.status} for ${periods.first.id}');
    // With a 30-day grace the previous month is usually still open;
    // anything 3+ months back must be expired.
    expect(periods[3].isOpen, isFalse,
        reason: '${periods[3].id} ended months ago and must be expired');
    expect(periods.last.isOpen, isFalse);
  });

  test('current quarterly and yearly periods are open', () async {
    final service = EthiopianPeriodService(db);
    for (final type in ['Quarterly', 'Yearly', 'SixMonthly']) {
      final periods =
          await service.periodsFor(dataSet: dataSet(type), count: 4);
      expect(periods.first.isOpen, isTrue,
          reason: 'current $type period ${periods.first.id} must be open');
    }
  });

  test('expiryDays == 0 never expires', () async {
    final periods = await EthiopianPeriodService(db)
        .periodsFor(dataSet: dataSet('Monthly', expiryDays: 0), count: 12);
    expect(periods.every((p) => p.isOpen), isTrue);
  });

  test(
      'monthly periods open the NEXT month early once today is the 21st or '
      'later (e.g. Nehase opens on Hamle 21) — and never emit a distinct '
      'Pagume (13) period, since this server has none', () async {
    final periods = await EthiopianPeriodService(db)
        .periodsFor(dataSet: dataSet('Monthly'), count: 12);
    final ethToday = EthiopianCalendar.today();

    // Pagume (month 13) only ever has 5-6 days, so day >= 21 can only
    // happen for an ordinary month (1-12) — the early-open branch
    // never has to consider wrapping out of Pagume itself.
    if (ethToday.day >= 21) {
      final nextMonth = ethToday.month == 12 ? 1 : ethToday.month + 1;
      final nextYear = ethToday.month == 12 ? ethToday.year + 1 : ethToday.year;
      final expectedId =
          '$nextYear${nextMonth.toString().padLeft(2, '0')}';
      expect(periods.first.id, expectedId,
          reason: 'on/after the 21st, the next month should be prepended');
      expect(periods.first.isOpen, isTrue);
    } else {
      // Within Pagume itself (month 13, always < day 21), "today"
      // normalizes to the upcoming Meskerem instead of a "…13" id.
      final expectedId = ethToday.month == 13
          ? '${ethToday.year + 1}01'
          : '${ethToday.year}${ethToday.month.toString().padLeft(2, '0')}';
      expect(periods.first.id, expectedId,
          reason: 'before the 21st, only the current month should lead');
    }
    expect(periods.any((p) => p.id.endsWith('13')), isFalse,
        reason: 'no period id should ever claim a distinct Pagume month');
  });

  group('statusForPeriod', () {
    // Reopening a report (or a form freshly opened after picking a
    // period) only has the period id, not the picker's whole list —
    // this is the one-off lookup that gates DataEntryPage's readOnly.
    test('agrees with periodsFor for the same period id', () async {
      final service = EthiopianPeriodService(db);
      final ds = dataSet('Monthly');
      final periods = await service.periodsFor(dataSet: ds, count: 12);

      final current = await service.statusForPeriod(
          dataSet: ds, periodId: periods.first.id);
      expect(current, PeriodStatus.open);

      final old = await service.statusForPeriod(
          dataSet: ds, periodId: periods[3].id);
      expect(old, PeriodStatus.expired,
          reason: '${periods[3].id} ended months ago');
    });

    test('expiryDays == 0 never expires', () async {
      final service = EthiopianPeriodService(db);
      final ds = dataSet('Monthly', expiryDays: 0);
      final periods = await service.periodsFor(dataSet: ds, count: 12);

      final status = await service.statusForPeriod(
          dataSet: ds, periodId: periods.last.id);
      expect(status, isNot(PeriodStatus.expired));
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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

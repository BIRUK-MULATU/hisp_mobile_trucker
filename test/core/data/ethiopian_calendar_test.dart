import 'package:flutter_test/flutter_test.dart';
import 'package:hisp_mobile_trucker/core/data/ethiopian_calendar.dart';

void main() {
  test('known anchor dates convert both ways', () {
    // Ethiopian New Year (Meskerem 1) 2017 EC = 11 Sep 2024 GC.
    expect(EthiopianCalendar.toGregorian(2017, 1, 1), DateTime(2024, 9, 11));
    // After an Ethiopian leap year (2015 EC), New Year falls on 12 Sep.
    expect(EthiopianCalendar.toGregorian(2016, 1, 1), DateTime(2023, 9, 12));
    // Hamle 1, 2018 EC = 8 Jul 2026 GC.
    expect(EthiopianCalendar.toGregorian(2018, 11, 1), DateTime(2026, 7, 8));

    final eth = EthiopianCalendar.toEthiopian(DateTime(2026, 7, 9));
    expect((eth.year, eth.month, eth.day), (2018, 11, 2));
  });

  test('toGregorian(toEthiopian(d)) round-trips across 40 years', () {
    for (var d = DateTime(2000, 1, 1);
        d.isBefore(DateTime(2040, 1, 1));
        d = d.add(const Duration(days: 17))) {
      final eth = EthiopianCalendar.toEthiopian(d);
      expect(EthiopianCalendar.toGregorian(eth.year, eth.month, eth.day), d,
          reason: 'round-trip failed for $d');
    }
  });

  test('Pagume length follows the leap cycle', () {
    expect(EthiopianCalendar.daysInMonth(2015, 13), 6); // leap
    expect(EthiopianCalendar.daysInMonth(2016, 13), 5);
    expect(EthiopianCalendar.daysInMonth(2019, 13), 6); // leap
    // Pagume 6, 2015 EC exists and lands on 11 Sep 2023.
    expect(EthiopianCalendar.toGregorian(2015, 13, 6), DateTime(2023, 9, 11));
  });

  // The Nov family is Ethiopian-fiscal-year aligned (Nov = month 11 =
  // Hamle on the Ethiopian-calendar server) and keyed by the EC year
  // the FY ENDS in. Anchors confirmed against staging analytics:
  // 2017Nov = "Hamle 2016 - Sene 2017", 2018NovQ1 = "Hamle 2017 -
  // Meskerem 2018", THIS_FINANCIAL_YEAR on 2026-07-09 = 2019Nov.
  group('Nov-family period ids', () {
    String currentId(String type) =>
        EthiopianCalendar.generatePeriods(periodType: type, count: 1)
            .first
            .id;

    // Derive the expected current ids from today's EC date the same
    // way the server does, so the test stays valid as time passes.
    final t = EthiopianCalendar.today();
    final fy = t.month >= 11 ? t.year + 1 : t.year;

    test('FinancialNov carries the Ethiopian fiscal END year', () {
      expect(currentId('FinancialNov'), '${fy}Nov');
    });

    test('QuarterlyNov starts its year at Hamle', () {
      final q = t.month >= 11 || t.month == 1
          ? 1
          : t.month <= 4
              ? 2
              : t.month <= 7
                  ? 3
                  : 4;
      expect(currentId('QuarterlyNov'), '${fy}NovQ$q');
    });

    test('SixMonthlyNov halves are Hamle–Tahsas / Tir–Sene', () {
      final s = (t.month >= 11 || t.month <= 4) ? 1 : 2;
      expect(currentId('SixMonthlyNov'), '${fy}NovS$s');
    });

    test('successive periods walk backwards without gaps', () {
      final ids = EthiopianCalendar.generatePeriods(
              periodType: 'QuarterlyNov', count: 6)
          .map((p) => p.id)
          .toList();
      expect(ids.toSet().length, 6, reason: 'no duplicates');
      for (final id in ids) {
        expect(RegExp(r'^\d{4}NovQ[1-4]$').hasMatch(id), isTrue,
            reason: 'bad id $id');
      }
      // Q1 of year y is preceded by Q4 of year y-1.
      final q1 = ids.indexWhere((id) => id.endsWith('Q1'));
      if (q1 >= 0 && q1 + 1 < ids.length) {
        final y = int.parse(ids[q1].substring(0, 4));
        expect(ids[q1 + 1], '${y - 1}NovQ4');
      }
    });
  });

  test('Daily ids are Ethiopian yyyyMMdd for today', () {
    final id = EthiopianCalendar.generatePeriods(
            periodType: 'Daily', count: 1)
        .first
        .id;
    final t = EthiopianCalendar.today();
    expect(
        id,
        '${t.year}${t.month.toString().padLeft(2, '0')}'
        '${t.day.toString().padLeft(2, '0')}');
  });

  test('formatPeriodId renders the new shapes', () {
    // 2018NovQ1 = Hamle 2017 – Meskerem 2018 (server-confirmed).
    expect(EthiopianCalendar.formatPeriodId('2018NovQ1'), contains('2017'));
    expect(EthiopianCalendar.formatPeriodId('2018NovQ1'), contains('2018'));
    expect(EthiopianCalendar.formatPeriodId('2018NovS2'), contains('2018'));
    // 2017Nov = Hamle 2016 – Sene 2017.
    final fin = EthiopianCalendar.formatPeriodId('2017Nov');
    expect(fin, contains('2016'));
    expect(fin, contains('2017'));
    // Daily 20181102 = 2 Hamle 2018.
    expect(EthiopianCalendar.formatPeriodId('20181102'), contains('2018'));
  });
}

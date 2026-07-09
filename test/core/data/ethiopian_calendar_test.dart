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
}

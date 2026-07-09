import '../database/app_database.dart';
import 'ethiopian_calendar.dart';
import 'period_access.dart';

/// Bridges the existing EthiopianCalendar utility (EFY labels on screen,
/// DHIS2 ISO ids on the wire) with data-entry period gating.
///
/// The period picker asks for the openable periods of a data set; each
/// comes back with its Amharic/English label, its DHIS2 id, and whether
/// it is currently open under expiryDays / openFuturePeriods.
class EthiopianPeriodService {
  EthiopianPeriodService(AppDatabase db) : _access = PeriodAccess(db);

  final PeriodAccess _access;

  /// Periods for the picker of one data set: most recent [count],
  /// Ethiopian-labelled, each carrying open/expired/notYetOpen status.
  Future<List<SelectablePeriod>> periodsFor({
    required DataSet dataSet,
    int count = 12,
  }) async {
    final periods = EthiopianCalendar.generatePeriods(
      periodType: dataSet.periodType,
      count: count,
    );

    final result = <SelectablePeriod>[];
    for (var i = 0; i < periods.length; i++) {
      final p = periods[i];
      final (start, end) = _gregorianBounds(p);
      // generatePeriods returns newest-first; index 0 is the current
      // (or newest generated) period. periodsAhead > 0 only applies if
      // the generator includes future periods; with newest = current,
      // everything here is 0 (current) or past.
      final status = await _access.statusOf(
        periodStart: start,
        periodEnd: end,
        expiryDays: dataSet.expiryDays,
        openFuturePeriods: dataSet.openFuturePeriods,
        periodsAhead: 0,
      );
      result.add(SelectablePeriod(
        id: p.id,
        labelAmharic: p.label,
        labelEnglish: p.labelEnglish,
        status: status,
      ));
    }
    return result;
  }

  /// Today's period id for a period type — the picker's default.
  String currentPeriodId(String periodType) {
    final periods =
        EthiopianCalendar.generatePeriods(periodType: periodType, count: 1);
    return periods.first.id;
  }

  /// Ungated period list for pickers without a dataset context
  /// (e.g. metadata not synced yet) — everything selectable.
  static List<SelectablePeriod> plainPeriodsFor({
    required String periodType,
    int count = 24,
  }) {
    final periods =
        EthiopianCalendar.generatePeriods(periodType: periodType, count: count);
    return [
      for (final p in periods)
        SelectablePeriod(
          id: p.id,
          labelAmharic: p.label,
          labelEnglish: p.labelEnglish,
          status: PeriodStatus.open,
        ),
    ];
  }

  /// Amharic display label for a stored DHIS2 period id.
  static String formatPeriodId(String periodId) =>
      EthiopianCalendar.formatPeriodId(periodId);

  /// Gregorian start/end of a period, derived from its DHIS2 id — the
  /// server runs the ETHIOPIAN calendar, so ids like 201811 mean
  /// Ethiopian year 2018, month 11 (Hamle). Expiry math compares
  /// against the device clock, so each id converts to Gregorian
  /// instants through the calendar.
  (DateTime, DateTime) _gregorianBounds(EthiopianPeriod p) {
    final id = p.id;

    // Last Gregorian day before the 1st of Ethiopian (year, month).
    DateTime dayBefore(int year, int month) => EthiopianCalendar
        .toGregorian(year, month, 1)
        .subtract(const Duration(days: 1));

    // Daily: EC yyyyMMdd — one Ethiopian day.
    final daily = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(id);
    if (daily != null) {
      final y = int.parse(daily.group(1)!);
      final m = int.parse(daily.group(2)!);
      final d = int.parse(daily.group(3)!);
      if (m >= 1 && m <= 13) {
        final day = EthiopianCalendar.toGregorian(y, m, d);
        return (day, day);
      }
    }
    // Monthly: yyyyMM (Ethiopian year, months 01–13 incl. Pagume)
    final monthly = RegExp(r'^(\d{4})(\d{2})$').firstMatch(id);
    if (monthly != null) {
      final y = int.parse(monthly.group(1)!);
      final m = int.parse(monthly.group(2)!);
      final end = m >= 13 ? dayBefore(y + 1, 1) : dayBefore(y, m + 1);
      return (EthiopianCalendar.toGregorian(y, m, 1), end);
    }
    // QuarterlyNov: yyyyNovQn — EFY quarters, Hamle-anchored:
    // Q1 Hamle(y-1)–Meskerem(y) incl. Pagume, Q2 Tikimt–Tahsas,
    // Q3 Tir–Megabit, Q4 Miyazia–Sene.
    final novQ = RegExp(r'^(\d{4})NovQ([1-4])$').firstMatch(id);
    if (novQ != null) {
      final y = int.parse(novQ.group(1)!);
      final q = int.parse(novQ.group(2)!);
      return switch (q) {
        1 => (EthiopianCalendar.toGregorian(y - 1, 11, 1), dayBefore(y, 2)),
        2 => (EthiopianCalendar.toGregorian(y, 2, 1), dayBefore(y, 5)),
        3 => (EthiopianCalendar.toGregorian(y, 5, 1), dayBefore(y, 8)),
        _ => (EthiopianCalendar.toGregorian(y, 8, 1), dayBefore(y, 11)),
      };
    }
    // Quarterly: yyyyQn — Q1 Meskerem–Hidar … Q4 Sene–Pagume
    final quarterly = RegExp(r'^(\d{4})Q([1-4])$').firstMatch(id);
    if (quarterly != null) {
      final y = int.parse(quarterly.group(1)!);
      final q = int.parse(quarterly.group(2)!);
      final end = q == 4 ? dayBefore(y + 1, 1) : dayBefore(y, q * 3 + 1);
      return (EthiopianCalendar.toGregorian(y, (q - 1) * 3 + 1, 1), end);
    }
    // SixMonthlyNov: yyyyNovSn — S1 Hamle(y-1)–Tahsas(y), S2 Tir–Sene.
    final novS = RegExp(r'^(\d{4})NovS([12])$').firstMatch(id);
    if (novS != null) {
      final y = int.parse(novS.group(1)!);
      return novS.group(2) == '1'
          ? (EthiopianCalendar.toGregorian(y - 1, 11, 1), dayBefore(y, 5))
          : (EthiopianCalendar.toGregorian(y, 5, 1), dayBefore(y, 11));
    }
    // SixMonthly: yyyySn — S1 Meskerem–Yekatit, S2 Megabit–Pagume
    final six = RegExp(r'^(\d{4})S([12])$').firstMatch(id);
    if (six != null) {
      final y = int.parse(six.group(1)!);
      final s = int.parse(six.group(2)!);
      final end = s == 1 ? dayBefore(y, 7) : dayBefore(y + 1, 1);
      return (EthiopianCalendar.toGregorian(y, s == 1 ? 1 : 7, 1), end);
    }
    // FinancialNov & friends: yyyyNov — Hamle (y-1) to Sene (y).
    final financial =
        RegExp(r'^(\d{4})(Nov|Jul|April|Oct)$').firstMatch(id);
    if (financial != null) {
      final y = int.parse(financial.group(1)!);
      final m = {'Nov': 11, 'Jul': 7, 'April': 4, 'Oct': 10}[
          financial.group(2)!]!;
      return (EthiopianCalendar.toGregorian(y - 1, m, 1), dayBefore(y, m));
    }
    // BiWeekly: yyyyBiWn — 14 EC days from Meskerem 1.
    final biW = RegExp(r'^(\d{4})BiW(\d{1,2})$').firstMatch(id);
    if (biW != null) {
      final y = int.parse(biW.group(1)!);
      final n = int.parse(biW.group(2)!);
      final start = EthiopianCalendar.toGregorian(y, 1, 1)
          .add(Duration(days: (n - 1) * 14));
      return (start, start.add(const Duration(days: 13)));
    }
    // Weekly: yyyyWn — the generator emits Gregorian ISO-week ids,
    // so these stay Gregorian.
    final weekly = RegExp(r'^(\d{4})W(\d{1,2})$').firstMatch(id);
    if (weekly != null) {
      final y = int.parse(weekly.group(1)!);
      final w = int.parse(weekly.group(2)!);
      final jan4 = DateTime(y, 1, 4);
      final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
      final start = week1Monday.add(Duration(days: (w - 1) * 7));
      return (start, start.add(const Duration(days: 6)));
    }
    // Yearly: yyyy — the full Ethiopian year.
    final yearly = RegExp(r'^(\d{4})$').firstMatch(id);
    if (yearly != null) {
      final y = int.parse(yearly.group(1)!);
      return (EthiopianCalendar.toGregorian(y, 1, 1), dayBefore(y + 1, 1));
    }
    // Financial year (2017Nov / 2017Jul / 2017Oct / 2017April) and
    // unknown formats: a generous two-Ethiopian-year window from the
    // year prefix — errs open; the server enforces exact expiry at
    // import anyway.
    final prefix = RegExp(r'^(\d{4})').firstMatch(id);
    if (prefix != null) {
      final y = int.parse(prefix.group(1)!);
      return (EthiopianCalendar.toGregorian(y, 1, 1), dayBefore(y + 2, 1));
    }
    return (DateTime(2000), DateTime(2000, 12, 31));
  }
}

class SelectablePeriod {
  const SelectablePeriod({
    required this.id,
    required this.labelAmharic,
    required this.labelEnglish,
    required this.status,
  });

  /// DHIS2 ISO id — what goes on the wire.
  final String id;

  /// What the user sees.
  final String labelAmharic;
  final String labelEnglish;

  final PeriodStatus status;

  bool get isOpen => status == PeriodStatus.open;
}

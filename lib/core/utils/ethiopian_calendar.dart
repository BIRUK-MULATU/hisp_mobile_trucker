/// Ethiopian Calendar Utility
/// Handles conversion between Gregorian and Ethiopian calendars
/// and generates period lists based on DHIS2 period types
class EthiopianCalendar {
  EthiopianCalendar._();

  // ── Ethiopian Month Names ──────────────────────────────────
  static const List<String> monthNamesAmharic = [
    'መስከረም', // 1 - Meskerem
    'ጥቅምት',  // 2 - Tikimit
    'ህዳር',   // 3 - Hidar
    'ታህሳስ',  // 4 - Tahsas
    'ጥር',    // 5 - Tir
    'የካቲት',  // 6 - Yekatit
    'መጋቢት',  // 7 - Megabit
    'ሚያዚያ',  // 8 - Miyazia
    'ግንቦት',  // 9 - Ginbot
    'ሰኔ',    // 10 - Sene
    'ሐምሌ',   // 11 - Hamle
    'ነሐሴ',   // 12 - Nehase
    'ጳጉሜ',   // 13 - Pagume
  ];

  static const List<String> monthNamesEnglish = [
    'Meskerem', // 1
    'Tikimit',  // 2
    'Hidar',    // 3
    'Tahsas',   // 4
    'Tir',      // 5
    'Yekatit',  // 6
    'Megabit',  // 7
    'Miyazia',  // 8
    'Ginbot',   // 9
    'Sene',     // 10
    'Hamle',    // 11
    'Nehase',   // 12
    'Pagume',   // 13
  ];

  // ── Ethiopian Quarter Names ────────────────────────────────
  static const List<String> quarterNamesAmharic = [
    'ሩብ 1', // Q1
    'ሩብ 2', // Q2
    'ሩብ 3', // Q3
    'ሩብ 4', // Q4
  ];

  // ── Convert Gregorian to Ethiopian ────────────────────────
  static EthiopianDate toEthiopian(DateTime gregorian) {
    final int jdn = _gregorianToJdn(
        gregorian.year, gregorian.month, gregorian.day);
    return _jdnToEthiopian(jdn);
  }

  /// Get current Ethiopian date
  static EthiopianDate today() {
    return toEthiopian(DateTime.now());
  }

  // ── Generate periods based on DHIS2 period type ───────────
  static List<EthiopianPeriod> generatePeriods({
    required String periodType,
    int count = 24,
  }) {
    switch (periodType.toUpperCase()) {
      case 'MONTHLY':
        return _generateMonthlyPeriods(count: count);
      case 'QUARTERLY':
        return _generateQuarterlyPeriods(count: count);
      case 'YEARLY':
      case 'ANNUAL':
        return _generateYearlyPeriods(count: count);
      case 'SIXMONTHLY':
        return _generateSixMonthlyPeriods(count: count);
      case 'WEEKLY':
        return _generateWeeklyPeriods(count: count);
      default:
        return _generateMonthlyPeriods(count: count);
    }
  }

  // ── Monthly periods ───────────────────────────────────────
  static List<EthiopianPeriod> _generateMonthlyPeriods({
    int count = 24,
  }) {
    final ethToday = today();
    final periods = <EthiopianPeriod>[];

    int year = ethToday.year;
    int month = ethToday.month;

    for (int i = 0; i < count; i++) {
      // DHIS2 Ethiopian monthly format: {year}Eth{mm}
      final id =
          '${year}Eth${month.toString().padLeft(2, '0')}';
      final label =
          '${monthNamesAmharic[month - 1]} $year';
      final labelEn =
          '${monthNamesEnglish[month - 1]} $year';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: year,
        month: month,
        type: PeriodType.monthly,
      ));

      // Go back one month
      month--;
      if (month < 1) {
        month = 13;
        year--;
      }
    }

    return periods;
  }

  // ── Quarterly periods ─────────────────────────────────────
  static List<EthiopianPeriod> _generateQuarterlyPeriods({
    int count = 8,
  }) {
    final ethToday = today();
    final periods = <EthiopianPeriod>[];

    int year = ethToday.year;
    // Ethiopian quarters: Q1=1-3, Q2=4-6, Q3=7-9, Q4=10-12
    int quarter = ((ethToday.month - 1) ~/ 3) + 1;

    for (int i = 0; i < count; i++) {
      final id = '${year}EthQ$quarter';
      final label = '${quarterNamesAmharic[quarter - 1]} $year';
      final labelEn = 'Q$quarter $year';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: year,
        quarter: quarter,
        type: PeriodType.quarterly,
      ));

      quarter--;
      if (quarter < 1) {
        quarter = 4;
        year--;
      }
    }

    return periods;
  }

  // ── Six-monthly periods ───────────────────────────────────
  static List<EthiopianPeriod> _generateSixMonthlyPeriods({
    int count = 6,
  }) {
    final ethToday = today();
    final periods = <EthiopianPeriod>[];

    int year = ethToday.year;
    int half = ethToday.month <= 6 ? 1 : 2;

    for (int i = 0; i < count; i++) {
      final id = '${year}EthS$half';
      final label = half == 1
          ? 'መስከረም - የካቲት $year'
          : 'መጋቢት - ነሐሴ $year';
      final labelEn = half == 1
          ? 'Meskerem - Yekatit $year'
          : 'Megabit - Nehase $year';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: year,
        half: half,
        type: PeriodType.sixMonthly,
      ));

      half--;
      if (half < 1) {
        half = 2;
        year--;
      }
    }

    return periods;
  }

  // ── Yearly periods ────────────────────────────────────────
  static List<EthiopianPeriod> _generateYearlyPeriods({
    int count = 5,
  }) {
    final ethToday = today();
    final periods = <EthiopianPeriod>[];

    int year = ethToday.year;

    for (int i = 0; i < count; i++) {
      final id = '${year}Eth';
      final label = 'ዓ.ም $year';
      final labelEn = 'Year $year';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: year,
        type: PeriodType.yearly,
      ));

      year--;
    }

    return periods;
  }

  // ── Weekly periods ────────────────────────────────────────
  static List<EthiopianPeriod> _generateWeeklyPeriods({
    int count = 12,
  }) {
    final now = DateTime.now();
    final periods = <EthiopianPeriod>[];

    for (int i = 0; i < count; i++) {
      final weekStart =
          now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final ethDate = toEthiopian(weekStart);

      // Get week number of the year
      final weekNum =
          (weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays /
                      7)
                  .floor() +
              1;

      final id = '${weekStart.year}W$weekNum';
      final label =
          'ሳምንት $weekNum - ${ethDate.year}';
      final labelEn = 'Week $weekNum - ${weekStart.year}';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: ethDate.year,
        week: weekNum,
        type: PeriodType.weekly,
      ));
    }

    return periods;
  }

  // ── Format a DHIS2 period ID to Ethiopian display ─────────
  static String formatPeriodId(String periodId) {
    try {
      // Monthly: 2016Eth01
      if (RegExp(r'^\d{4}Eth\d{2}$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final month = int.parse(periodId.substring(7, 9));
        if (month >= 1 && month <= 13) {
          return '${monthNamesAmharic[month - 1]} $year';
        }
      }

      // Quarterly: 2016EthQ1
      if (RegExp(r'^\d{4}EthQ\d$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final quarter = int.parse(periodId.substring(8));
        return '${quarterNamesAmharic[quarter - 1]} $year';
      }

      // Yearly: 2016Eth
      if (RegExp(r'^\d{4}Eth$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        return 'ዓ.ም $year';
      }

      // Gregorian monthly fallback: 202401
      if (RegExp(r'^\d{6}$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final month = int.parse(periodId.substring(4, 6));
        final ethDate = toEthiopian(DateTime(year, month, 1));
        if (ethDate.month >= 1 && ethDate.month <= 13) {
          return '${monthNamesAmharic[ethDate.month - 1]} ${ethDate.year}';
        }
      }

      return periodId;
    } catch (_) {
      return periodId;
    }
  }

  // ── Internal: Gregorian to Julian Day Number ───────────────
  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  // ── Internal: Julian Day Number to Ethiopian ───────────────
  static EthiopianDate _jdnToEthiopian(int jdn) {
    final r = (jdn - 1723856) % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - 1723856) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    final month = n ~/ 30 + 1;
    final day = n % 30 + 1;
    return EthiopianDate(year: year, month: month, day: day);
  }
}

// ── Ethiopian Date model ───────────────────────────────────────
class EthiopianDate {
  final int year;
  final int month;
  final int day;

  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  String get monthNameAmharic =>
      EthiopianCalendar.monthNamesAmharic[month - 1];

  String get monthNameEnglish =>
      EthiopianCalendar.monthNamesEnglish[month - 1];

  @override
  String toString() => '$day $monthNameAmharic $year';
}

// ── Period model ───────────────────────────────────────────────
class EthiopianPeriod {
  final String id;
  final String label;       // Amharic label
  final String labelEnglish;
  final int year;
  final int? month;
  final int? quarter;
  final int? half;
  final int? week;
  final PeriodType type;

  const EthiopianPeriod({
    required this.id,
    required this.label,
    required this.labelEnglish,
    required this.year,
    this.month,
    this.quarter,
    this.half,
    this.week,
    required this.type,
  });
}

// ── Period types ───────────────────────────────────────────────
enum PeriodType {
  monthly,
  quarterly,
  sixMonthly,
  yearly,
  weekly,
}

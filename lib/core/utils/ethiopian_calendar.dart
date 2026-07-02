class EthiopianCalendar {
  EthiopianCalendar._();

  static const List<String> monthNamesAmharic = [
    'መስከረም', 'ጥቅምት', 'ህዳር', 'ታህሳስ',
    'ጥር', 'የካቲት', 'መጋቢት', 'ሚያዚያ',
    'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ',
  ];

  static const List<String> monthNamesEnglish = [
    'Meskerem', 'Tikimit', 'Hidar', 'Tahsas',
    'Tir', 'Yekatit', 'Megabit', 'Miyazia',
    'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
  ];

  static const List<String> quarterNamesAmharic = [
    'ሩብ 1', 'ሩብ 2', 'ሩብ 3', 'ሩብ 4',
  ];

  // ── Convert Gregorian to Ethiopian ────────────────────────
  static EthiopianDate toEthiopian(DateTime gregorian) {
    final int jdn = _gregorianToJdn(
        gregorian.year, gregorian.month, gregorian.day);
    return _jdnToEthiopian(jdn);
  }

  static EthiopianDate today() => toEthiopian(DateTime.now());

  // ── Generate periods based on DHIS2 period type ───────────
  static List<EthiopianPeriod> generatePeriods({
    required String periodType,
    int count = 24,
  }) {
    final type = periodType.toUpperCase();
    if (type.contains('FINANCIAL') || type == 'FINANCIALNOV' ||
        type == 'FINANCIALJUL' || type == 'FINANCIALAP' ||
        type == 'FINANCIALOCT') {
      return _generateFinancialPeriods(
          periodType: periodType, count: count);
    }
    switch (type) {
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

  // ── Financial Year Periods ─────────────────────────────────
  // DHIS2 Financial periods: 2017Nov, 2017Jul, 2017April, 2017Oct
  static List<EthiopianPeriod> _generateFinancialPeriods({
    required String periodType,
    int count = 10,
  }) {
    final now = DateTime.now();
    final periods = <EthiopianPeriod>[];

    // Determine suffix and start month
    String suffix;
    int startMonth;
    String startMonthName;

    final type = periodType.toUpperCase();
    if (type == 'FINANCIALNOV' || type.contains('NOV')) {
      suffix = 'Nov';
      startMonth = 11; // November
      startMonthName = 'Nov';
    } else if (type == 'FINANCIALJUL' || type.contains('JUL')) {
      suffix = 'Jul';
      startMonth = 7;
      startMonthName = 'Jul';
    } else if (type == 'FINANCIALAPRIL' ||
        type == 'FINANCIALAP' ||
        type.contains('APR')) {
      suffix = 'April';
      startMonth = 4;
      startMonthName = 'Apr';
    } else if (type == 'FINANCIALOCT' || type.contains('OCT')) {
      suffix = 'Oct';
      startMonth = 10;
      startMonthName = 'Oct';
    } else {
      suffix = 'Nov';
      startMonth = 11;
      startMonthName = 'Nov';
    }

    // Find current financial year start
    int currentYear = now.year;
    if (now.month < startMonth) currentYear--;

    for (int i = 0; i < count; i++) {
      final year = currentYear - i;
      final endYear = year + 1;

      // DHIS2 format: 2017Nov
      final id = '$year$suffix';
      // Display: "ህዳር 2010 - ጥቅምት 2011" (Ethiopian)
      final ethStart =
          toEthiopian(DateTime(year, startMonth, 1));
      final ethEnd =
          toEthiopian(DateTime(endYear, startMonth - 1, 1));
      final label =
          '${monthNamesAmharic[ethStart.month - 1]} ${ethStart.year} '
          '- ${monthNamesAmharic[ethEnd.month - 1]} ${ethEnd.year}';
      final labelEn =
          '$startMonthName $year - $startMonthName $endYear';

      periods.add(EthiopianPeriod(
        id: id,
        label: label,
        labelEnglish: labelEn,
        year: year,
        type: PeriodType.financial,
      ));
    }

    return periods;
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
      // DHIS2 monthly period ID: yyyyMM
      final id =
          '$year${month.toString().padLeft(2, '0')}';
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
    int quarter = ((ethToday.month - 1) ~/ 3) + 1;

    for (int i = 0; i < count; i++) {
      // DHIS2 quarterly period ID: yyyyQn
      final id = '${year}Q$quarter';
      final label =
          '${quarterNamesAmharic[quarter - 1]} $year';
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
      // DHIS2 six-monthly period ID: yyyySn
      final id = '${year}S$half';
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
      // DHIS2 yearly period ID: yyyy
      final id = '$year';
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
      final weekStart = now
          .subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekNum =
          (weekStart.difference(DateTime(weekStart.year, 1, 1))
                          .inDays /
                      7)
                  .floor() +
              1;
      final id = '${weekStart.year}W$weekNum';
      final ethDate = toEthiopian(weekStart);
      final label = 'ሳምንት $weekNum - ${ethDate.year}';
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

  // ── Format period ID for display ──────────────────────────
  static String formatPeriodId(String periodId) {
    try {
      // Financial: 2017Nov, 2017Jul, 2017April, 2017Oct
      final financialMatch = RegExp(
              r'^(\d{4})(Nov|Jul|April|Oct|Apr)$',
              caseSensitive: false)
          .firstMatch(periodId);
      if (financialMatch != null) {
        final year = int.parse(financialMatch.group(1)!);
        final suffix = financialMatch.group(2)!;
        final endYear = year + 1;
        return _financialLabel(year, endYear, suffix);
      }

      // Legacy Ethiopian Monthly (pre-fix local data): 2016Eth01
      if (RegExp(r'^\d{4}Eth\d{2}$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final month = int.parse(periodId.substring(7, 9));
        if (month >= 1 && month <= 13) {
          return '${monthNamesAmharic[month - 1]} $year';
        }
      }

      // Legacy Ethiopian Quarterly (pre-fix local data): 2016EthQ1
      if (RegExp(r'^\d{4}EthQ\d$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final quarter = int.parse(periodId.substring(8));
        return '${quarterNamesAmharic[quarter - 1]} $year';
      }

      // Legacy Ethiopian SixMonthly (pre-fix local data): 2016EthS1
      if (RegExp(r'^\d{4}EthS\d$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final half = int.parse(periodId.substring(8));
        return half == 1
            ? 'መስከረም - የካቲት $year'
            : 'መጋቢት - ነሐሴ $year';
      }

      // Legacy Ethiopian Yearly (pre-fix local data): 2016Eth
      if (RegExp(r'^\d{4}Eth$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        return 'ዓ.ም $year';
      }

      // Monthly: yyyyMM (Ethiopian year/month, DHIS2 ISO format)
      if (RegExp(r'^\d{6}$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final month = int.parse(periodId.substring(4, 6));
        if (month >= 1 && month <= 13) {
          return '${monthNamesAmharic[month - 1]} $year';
        }
      }

      // Quarterly: yyyyQn
      if (RegExp(r'^\d{4}Q\d$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final quarter = int.parse(periodId.substring(5));
        return '${quarterNamesAmharic[quarter - 1]} $year';
      }

      // SixMonthly: yyyySn
      if (RegExp(r'^\d{4}S\d$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        final half = int.parse(periodId.substring(5));
        return half == 1
            ? 'መስከረም - የካቲት $year'
            : 'መጋቢት - ነሐሴ $year';
      }

      // Yearly: yyyy
      if (RegExp(r'^\d{4}$').hasMatch(periodId)) {
        final year = int.parse(periodId.substring(0, 4));
        return 'ዓ.ም $year';
      }

      return periodId;
    } catch (_) {
      return periodId;
    }
  }

  static String _financialLabel(
      int year, int endYear, String suffix) {
    // Map Gregorian month to Ethiopian
    final Map<String, int> monthMap = {
      'Nov': 11, 'Jul': 7,
      'April': 4, 'Apr': 4, 'Oct': 10,
    };
    final startMonth =
        monthMap[suffix] ?? monthMap[suffix.toLowerCase()] ?? 11;
    final ethStart =
        toEthiopian(DateTime(year, startMonth, 1));
    final ethEnd =
        toEthiopian(DateTime(endYear, startMonth - 1, 30));
    return '${monthNamesAmharic[ethStart.month - 1]} '
        '${ethStart.year} - '
        '${monthNamesAmharic[ethEnd.month - 1]} '
        '${ethEnd.year}';
  }

  // ── Internal conversions ──────────────────────────────────
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

  static EthiopianDate _jdnToEthiopian(int jdn) {
    final r = (jdn - 1723856) % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    final year =
        4 * ((jdn - 1723856) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    final month = n ~/ 30 + 1;
    final day = n % 30 + 1;
    return EthiopianDate(year: year, month: month, day: day);
  }
}

// ── Ethiopian Date ─────────────────────────────────────────────
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
  final String label;
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
  financial,
}

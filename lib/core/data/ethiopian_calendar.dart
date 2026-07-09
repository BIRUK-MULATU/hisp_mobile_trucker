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

  // ── Convert Ethiopian to Gregorian ────────────────────────
  static DateTime toGregorian(int year, int month, int day) =>
      _jdnToGregorian(_ethiopianToJdn(year, month, day));

  /// Days in an Ethiopian month: 1–12 have 30, Pagume has 5
  /// (6 in leap years, i.e. when year % 4 == 3).
  static int daysInMonth(int year, int month) =>
      month < 13 ? 30 : (year % 4 == 3 ? 6 : 5);

  // ── Generate periods based on DHIS2 period type ───────────
  //
  // The "Nov" family (QuarterlyNov / SixMonthlyNov / FinancialNov) is
  // NOT Gregorian November: on a server running the Ethiopian
  // calendar, Nov = month 11 = Hamle, so these periods align to the
  // Ethiopian fiscal year (Hamle 1 – Sene 30) and their ids carry the
  // ETHIOPIAN year. Verified against staging analytics: 2017Nov =
  // "Hamle 2016 - Sene 2017", 2018NovQ1 = "Hamle 2017 - Meskerem 2018".
  static List<EthiopianPeriod> generatePeriods({
    required String periodType,
    int count = 24,
  }) {
    final type = periodType.toUpperCase();
    if (type.contains('FINANCIAL')) {
      return _generateFinancialPeriods(
          periodType: periodType, count: count);
    }
    switch (type) {
      case 'MONTHLY':
        return _generateMonthlyPeriods(count: count);
      case 'DAILY':
        return _generateDailyPeriods(count: count);
      case 'QUARTERLY':
        return _generateQuarterlyPeriods(count: count);
      case 'QUARTERLYNOV':
        return _generateQuarterlyNovPeriods(count: count);
      case 'YEARLY':
      case 'ANNUAL':
        return _generateYearlyPeriods(count: count);
      case 'SIXMONTHLY':
        return _generateSixMonthlyPeriods(count: count);
      case 'SIXMONTHLYNOV':
        return _generateSixMonthlyNovPeriods(count: count);
      case 'WEEKLY':
        return _generateWeeklyPeriods(count: count);
      case 'BIWEEKLY':
        return _generateBiWeeklyPeriods(count: count);
      default:
        return _generateMonthlyPeriods(count: count);
    }
  }

  /// Ethiopian fiscal year an EC (year, month) falls in: the FY id
  /// carries the year it ENDS in — Hamle..Pagume belong to NEXT year's
  /// fiscal id (2018NovQ1 starts Hamle 2017).
  static int _fiscalYearOf(int ecYear, int ecMonth) =>
      ecMonth >= 11 ? ecYear + 1 : ecYear;

  // ── QuarterlyNov: yyyyNovQn, EFY-aligned quarters ──────────
  //   Q1 Hamle–Meskerem (incl. Pagume), Q2 Tikimt–Tahsas,
  //   Q3 Tir–Megabit, Q4 Miyazia–Sene.
  static List<EthiopianPeriod> _generateQuarterlyNovPeriods({
    int count = 8,
  }) {
    // (start month index in the label, end month index, wraps year)
    const spans = [(10, 0, true), (1, 3, false), (4, 6, false), (7, 9, false)];
    final ethToday = today();
    int year = _fiscalYearOf(ethToday.year, ethToday.month);
    int quarter = switch (ethToday.month) {
      >= 11 || 1 => 1,
      >= 2 && <= 4 => 2,
      >= 5 && <= 7 => 3,
      _ => 4,
    };

    final periods = <EthiopianPeriod>[];
    for (int i = 0; i < count; i++) {
      final (s, e, wraps) = spans[quarter - 1];
      final startYear = wraps ? year - 1 : year;
      periods.add(EthiopianPeriod(
        id: '${year}NovQ$quarter',
        label: '${monthNamesAmharic[s]} $startYear - '
            '${monthNamesAmharic[e]} $year',
        labelEnglish: '${monthNamesEnglish[s]} $startYear - '
            '${monthNamesEnglish[e]} $year',
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

  // ── SixMonthlyNov: yyyyNovSn, EFY-aligned halves ───────────
  //   S1 Hamle–Tahsas, S2 Tir–Sene.
  static List<EthiopianPeriod> _generateSixMonthlyNovPeriods({
    int count = 6,
  }) {
    final ethToday = today();
    int year = _fiscalYearOf(ethToday.year, ethToday.month);
    int half = (ethToday.month >= 11 || ethToday.month <= 4) ? 1 : 2;

    final periods = <EthiopianPeriod>[];
    for (int i = 0; i < count; i++) {
      periods.add(EthiopianPeriod(
        id: '${year}NovS$half',
        label: half == 1
            ? 'ሐምሌ ${year - 1} - ታህሳስ $year'
            : 'ጥር $year - ሰኔ $year',
        labelEnglish: half == 1
            ? 'Hamle ${year - 1} - Tahsas $year'
            : 'Tir $year - Sene $year',
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

  // ── Daily: EC yyyyMMdd (server calendar is Ethiopian) ──────
  static List<EthiopianPeriod> _generateDailyPeriods({int count = 30}) {
    var day = DateTime.now();
    final periods = <EthiopianPeriod>[];
    for (int i = 0; i < count; i++) {
      final e = toEthiopian(day);
      periods.add(EthiopianPeriod(
        id: '${e.year}'
            '${e.month.toString().padLeft(2, '0')}'
            '${e.day.toString().padLeft(2, '0')}',
        label: '${e.day} ${monthNamesAmharic[e.month - 1]} ${e.year}',
        labelEnglish: '${e.day} ${monthNamesEnglish[e.month - 1]} ${e.year}',
        year: e.year,
        month: e.month,
        type: PeriodType.daily,
      ));
      day = day.subtract(const Duration(days: 1));
    }
    return periods;
  }

  // ── BiWeekly: yyyyBiWn, 14-day blocks from Meskerem 1 ──────
  static List<EthiopianPeriod> _generateBiWeeklyPeriods({int count = 12}) {
    final ethToday = today();
    int year = ethToday.year;
    int biWeek = ((ethToday.month - 1) * 30 + ethToday.day - 1) ~/ 14 + 1;

    final periods = <EthiopianPeriod>[];
    for (int i = 0; i < count; i++) {
      periods.add(EthiopianPeriod(
        id: '${year}BiW$biWeek',
        label: 'ሳምንት ${biWeek * 2 - 1}-${biWeek * 2} $year',
        labelEnglish: 'Bi-week $biWeek $year',
        year: year,
        week: biWeek,
        type: PeriodType.biWeekly,
      ));
      biWeek--;
      if (biWeek < 1) {
        // 365/366 EC days per year → 27 bi-weeks (the last is short).
        biWeek = 27;
        year--;
      }
    }
    return periods;
  }

  // ── Financial Year Periods ─────────────────────────────────
  // On this ETHIOPIAN-calendar server "Nov" = month 11 = Hamle, and
  // the id carries the ETHIOPIAN year the FY ends in: 2017Nov spans
  // Hamle 2016 – Sene 2017 (confirmed against staging analytics).
  // Other Financial* variants follow the same month-11-relative rule
  // in the server calendar (none are in use on staging today).
  static List<EthiopianPeriod> _generateFinancialPeriods({
    required String periodType,
    int count = 10,
  }) {
    final type = periodType.toUpperCase();
    final suffix = type.contains('JUL')
        ? 'Jul'
        : type.contains('APR')
            ? 'April'
            : type.contains('OCT')
                ? 'Oct'
                : 'Nov';
    final startMonth = {'Jul': 7, 'April': 4, 'Oct': 10, 'Nov': 11}[suffix]!;

    final ethToday = today();
    int year = ethToday.month >= startMonth
        ? ethToday.year + 1
        : ethToday.year;

    final periods = <EthiopianPeriod>[];
    for (int i = 0; i < count; i++) {
      final y = year - i;
      final startName = monthNamesAmharic[startMonth - 1];
      final endName = monthNamesAmharic[startMonth - 2];
      final startNameEn = monthNamesEnglish[startMonth - 1];
      final endNameEn = monthNamesEnglish[startMonth - 2];
      periods.add(EthiopianPeriod(
        id: '$y$suffix',
        label: '$startName ${y - 1} - $endName $y',
        labelEnglish: '$startNameEn ${y - 1} - $endNameEn $y',
        year: y,
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
      // QuarterlyNov: 2018NovQ1 — EFY quarter (Hamle-anchored).
      final novQ =
          RegExp(r'^(\d{4})NovQ([1-4])$').firstMatch(periodId);
      if (novQ != null) {
        final y = int.parse(novQ.group(1)!);
        final q = int.parse(novQ.group(2)!);
        const spans = [(10, 0, true), (1, 3, false), (4, 6, false), (7, 9, false)];
        final (s, e, wraps) = spans[q - 1];
        return '${monthNamesAmharic[s]} ${wraps ? y - 1 : y} - '
            '${monthNamesAmharic[e]} $y';
      }

      // SixMonthlyNov: 2018NovS1 — EFY half.
      final novS = RegExp(r'^(\d{4})NovS([12])$').firstMatch(periodId);
      if (novS != null) {
        final y = int.parse(novS.group(1)!);
        return novS.group(2) == '1'
            ? 'ሐምሌ ${y - 1} - ታህሳስ $y'
            : 'ጥር $y - ሰኔ $y';
      }

      // BiWeekly: 2018BiW1 — 14-day blocks from Meskerem 1.
      final biW = RegExp(r'^(\d{4})BiW(\d{1,2})$').firstMatch(periodId);
      if (biW != null) {
        final n = int.parse(biW.group(2)!);
        return 'ሳምንት ${n * 2 - 1}-${n * 2} ${biW.group(1)}';
      }

      // Daily: EC yyyyMMdd.
      final daily =
          RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(periodId);
      if (daily != null) {
        final m = int.parse(daily.group(2)!);
        if (m >= 1 && m <= 13) {
          return '${int.parse(daily.group(3)!)} '
              '${monthNamesAmharic[m - 1]} ${daily.group(1)}';
        }
      }

      // Financial: 2017Nov, 2017Jul, 2017April, 2017Oct — start month
      // is in the SERVER (Ethiopian) calendar; id year = end year.
      final financialMatch = RegExp(
              r'^(\d{4})(Nov|Jul|April|Oct|Apr)$',
              caseSensitive: false)
          .firstMatch(periodId);
      if (financialMatch != null) {
        final year = int.parse(financialMatch.group(1)!);
        final suffix = financialMatch.group(2)!;
        return _financialLabel(year, suffix);
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

  static String _financialLabel(int year, String suffix) {
    // Start month in the SERVER calendar (Nov = Hamle on an
    // Ethiopian-calendar DHIS2); the id year is the fiscal END year.
    final Map<String, int> monthMap = {
      'Nov': 11, 'Jul': 7,
      'April': 4, 'Apr': 4, 'Oct': 10,
    };
    final startMonth = monthMap[suffix] ?? 11;
    return '${monthNamesAmharic[startMonth - 1]} ${year - 1} - '
        '${monthNamesAmharic[startMonth - 2]} $year';
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

  static int _ethiopianToJdn(int year, int month, int day) =>
      1723856 + 365 * year + year ~/ 4 + 30 * (month - 1) + day - 1;

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    return DateTime(
      100 * b + d - 4800 + m ~/ 10,
      m + 3 - 12 * (m ~/ 10),
      e - (153 * m + 2) ~/ 5 + 1,
    );
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
  daily,
  monthly,
  quarterly,
  sixMonthly,
  yearly,
  weekly,
  biWeekly,
  financial,
}

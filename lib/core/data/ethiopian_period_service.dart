import '../database/app_database.dart';
import '../utils/ethiopian_calendar.dart';
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

  /// Gregorian start/end of a period, derived from its DHIS2 id — the
  /// server's calendar is Gregorian, so expiry math must be too, even
  /// though the LABELS are Ethiopian.
  (DateTime, DateTime) _gregorianBounds(EthiopianPeriod p) {
    final id = p.id;

    // Monthly: yyyyMM
    final monthly = RegExp(r'^(\d{4})(\d{2})$').firstMatch(id);
    if (monthly != null) {
      final y = int.parse(monthly.group(1)!);
      final m = int.parse(monthly.group(2)!);
      return (DateTime(y, m, 1), DateTime(y, m + 1, 0));
    }
    // Quarterly: yyyyQn
    final quarterly = RegExp(r'^(\d{4})Q([1-4])$').firstMatch(id);
    if (quarterly != null) {
      final y = int.parse(quarterly.group(1)!);
      final q = int.parse(quarterly.group(2)!);
      final startMonth = (q - 1) * 3 + 1;
      return (DateTime(y, startMonth, 1), DateTime(y, startMonth + 3, 0));
    }
    // SixMonthly: yyyySn
    final six = RegExp(r'^(\d{4})S([12])$').firstMatch(id);
    if (six != null) {
      final y = int.parse(six.group(1)!);
      final s = int.parse(six.group(2)!);
      final startMonth = s == 1 ? 1 : 7;
      return (DateTime(y, startMonth, 1), DateTime(y, startMonth + 6, 0));
    }
    // Weekly: yyyyWn — ISO week
    final weekly = RegExp(r'^(\d{4})W(\d{1,2})$').firstMatch(id);
    if (weekly != null) {
      final y = int.parse(weekly.group(1)!);
      final w = int.parse(weekly.group(2)!);
      final jan4 = DateTime(y, 1, 4);
      final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
      final start = week1Monday.add(Duration(days: (w - 1) * 7));
      return (start, start.add(const Duration(days: 6)));
    }
    // Financial year (2017Nov / 2017Jul / 2017Oct / 2017April) and
    // plain Yearly (yyyy): approximate with the year span; financial
    // start months refine later if a dataset needs day-exact expiry.
    final yearly = RegExp(r'^(\d{4})').firstMatch(id);
    if (yearly != null) {
      final y = int.parse(yearly.group(1)!);
      return (DateTime(y, 1, 1), DateTime(y, 12, 31));
    }
    // Unknown format: treat as open-ended past period.
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

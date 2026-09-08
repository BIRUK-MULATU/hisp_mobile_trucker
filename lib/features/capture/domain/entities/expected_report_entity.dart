/// How pressing an outstanding report is.
enum ReportUrgency {
  /// The period has ended but is still inside its lock window — fill it now.
  overdue,

  /// The period is ending within a few days.
  dueSoon,

  /// Open, deadline not yet close.
  open,
}

/// One report the user is EXPECTED to fill but hasn't completed: a
/// dataset assigned to one of their facilities, for a period that is
/// still open for entry. Computed on the fly from
/// `dataSetOrgUnitsTable` × open periods − completions
/// (see `CaptureRepository.getExpectedReports`); never stored.
class ExpectedReportEntity {
  const ExpectedReportEntity({
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.periodId,
    required this.periodLabel,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.periodEnd,
    required this.urgency,
    this.lockDate,
    this.isDiseaseRegistration = false,
    this.needsComboPick = false,
    this.localStarted = false,
  });

  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String periodId;

  /// Ethiopian label, e.g. "Hamle 2016".
  final String periodLabel;
  final String orgUnitId;
  final String orgUnitName;

  /// Last Gregorian day of the reporting period.
  final DateTime periodEnd;

  /// When the server will refuse the report — `periodEnd + expiryDays`.
  /// Null when the dataset has `expiryDays == 0` (never locks).
  final DateTime? lockDate;

  final ReportUrgency urgency;
  final bool isDiseaseRegistration;

  /// The dataset carries a real category combination (e.g. Disease
  /// Registration's Department × Outcome) — opening it needs the combo
  /// picker step, not a straight jump into the form.
  final bool needsComboPick;

  /// The user has already entered/queued something for this report but
  /// not completed it — a "resume" rather than a "start".
  final bool localStarted;

  /// Stable key for reminder ids / de-duping.
  String get key => '${dataSetId}_${orgUnitId}_$periodId';
}

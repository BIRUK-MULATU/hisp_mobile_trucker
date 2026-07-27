/// Local lifecycle of one report instance.
enum ReportStatus {
  /// Un-uploaded local work (drafts, queued or rejected values)
  /// without a completion sign-off — the report is still open.
  incomplete,

  /// A completed-data-set registration exists (sent or queued).
  completed,
}

/// One report the user has worked on: dataset × period × org unit.
/// The "Report Period" overview lists these across ALL org units —
/// it is about the user's work, not the currently selected org unit.
class ReportInstanceEntity {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String periodId;

  /// Human-readable Ethiopian period (e.g. 'Hamle 2016').
  final String periodLabel;
  final String orgUnitId;
  final String orgUnitName;
  final ReportStatus status;

  /// True when everything local for this report is on the server:
  /// no draft/pending/error values and the completion registration
  /// (if any) has been pushed.
  final bool synced;

  /// Most recent local change — the list sorts newest first.
  final DateTime lastModified;

  /// The server's verdict when the completion push was REJECTED
  /// (e.g. "Data set X is not assigned to organisation unit Y") —
  /// null while pending or synced. Shown on the card so a stuck
  /// report explains itself instead of just staying red.
  final String? syncError;

  const ReportInstanceEntity({
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.periodId,
    required this.periodLabel,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.status,
    required this.synced,
    required this.lastModified,
    this.syncError,
  });
}

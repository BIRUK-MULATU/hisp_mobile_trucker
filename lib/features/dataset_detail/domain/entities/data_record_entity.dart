class DataRecordEntity {
  final String id;
  final String dataSetId;
  final String periodId;
  final String orgUnitId;
  final String? orgUnitName;
  final String? periodName;
  final RecordStatus status;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final Map<String, dynamic> dataValues;

  const DataRecordEntity({
    required this.id,
    required this.dataSetId,
    required this.periodId,
    required this.orgUnitId,
    this.orgUnitName,
    this.periodName,
    this.status = RecordStatus.incomplete,
    this.createdAt,
    this.lastUpdated,
    this.dataValues = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataRecordEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum RecordStatus {
  complete,
  incomplete,
  draft,
}

import '../../domain/entities/data_record_entity.dart';

class DataRecordModel extends DataRecordEntity {
  const DataRecordModel({
    required super.id,
    required super.dataSetId,
    required super.periodId,
    required super.orgUnitId,
    super.orgUnitName,
    super.periodName,
    super.status,
    super.createdAt,
    super.lastUpdated,
    super.dataValues,
    super.isSynced,
  });

  factory DataRecordModel.fromJson(Map<String, dynamic> json) {
    return DataRecordModel(
      id: json['id'] as String? ?? '',
      dataSetId: json['dataSet']?['id'] as String? ?? '',
      periodId: json['period'] as String? ?? '',
      orgUnitId: json['orgUnit']?['id'] as String? ?? '',
      orgUnitName: json['orgUnit']?['displayName'] as String?,
      periodName: json['period'] as String?,
      status: _parseStatus(json['completeDate']),
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
      dataValues: json['dataValues'] as Map<String, dynamic>? ?? {},
      // Records returned by the server are, by definition, already synced.
      // Locally-created records not yet pushed should be created with
      // isSynced: false until the push succeeds.
      isSynced: true,
    );
  }

  static RecordStatus _parseStatus(dynamic completeDate) {
    if (completeDate != null) return RecordStatus.complete;
    return RecordStatus.incomplete;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataSet': {'id': dataSetId},
        'period': periodId,
        'orgUnit': {'id': orgUnitId},
        'dataValues': dataValues,
      };
}

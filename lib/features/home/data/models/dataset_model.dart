import '../../domain/entities/dataset_entity.dart';

class DataSetModel extends DataSetEntity {
  const DataSetModel({
    required super.id,
    required super.name,
    super.shortName,
    super.description,
    required super.periodType,
    super.syncStatus,
    super.iconType,
    super.lastSynced,
  });

  factory DataSetModel.fromJson(Map<String, dynamic> json) {
    return DataSetModel(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ?? json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      description: json['description'] as String?,
      periodType: json['periodType'] as String? ?? 'Monthly',
      syncStatus: SyncStatus.unsynced,
      iconType: json['style']?['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'description': description,
        'periodType': periodType,
      };

  DataSetModel copyWith({SyncStatus? syncStatus}) {
    return DataSetModel(
      id: id,
      name: name,
      shortName: shortName,
      description: description,
      periodType: periodType,
      syncStatus: syncStatus ?? this.syncStatus,
      iconType: iconType,
      lastSynced: lastSynced,
    );
  }
}

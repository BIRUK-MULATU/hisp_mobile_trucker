import '../../domain/entities/dataset_section_entity.dart';

class DataSetSectionModel extends DataSetSectionEntity {
  const DataSetSectionModel({
    required super.id,
    required super.name,
    super.description,
    super.sortOrder,
  });

  factory DataSetSectionModel.fromJson(Map<String, dynamic> json) {
    return DataSetSectionModel(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

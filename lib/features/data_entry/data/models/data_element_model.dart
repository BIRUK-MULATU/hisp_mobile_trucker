import '../../domain/entities/data_element_entity.dart';

class CategoryOptionComboModel extends CategoryOptionCombo {
  const CategoryOptionComboModel({
    required super.id,
    required super.name,
    super.shortName,
  });

  factory CategoryOptionComboModel.fromJson(
      Map<String, dynamic> json) {
    return CategoryOptionComboModel(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ??
          json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
    );
  }
}

class DataElementModel extends DataElementEntity {
  const DataElementModel({
    required super.id,
    required super.name,
    super.shortName,
    super.valueType,
    super.categoryComboId,
    super.categoryOptionCombos,
  });

  factory DataElementModel.fromJson(Map<String, dynamic> json) {
    final categoryOptionCombos =
        (json['categoryCombo']?['categoryOptionCombos']
                    as List<dynamic>? ??
                [])
            .map((e) => CategoryOptionComboModel.fromJson(
                e as Map<String, dynamic>))
            .toList();

    return DataElementModel(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ??
          json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      valueType: json['valueType'] as String? ?? 'NUMBER',
      categoryComboId:
          json['categoryCombo']?['id'] as String?,
      categoryOptionCombos: categoryOptionCombos,
    );
  }
}

class DataValueModel extends DataValueEntity {
  DataValueModel({
    required super.dataElementId,
    required super.categoryOptionComboId,
    required super.orgUnitId,
    required super.period,
    super.value,
    super.isModified,
  });

  factory DataValueModel.fromJson(Map<String, dynamic> json) {
    return DataValueModel(
      dataElementId: json['dataElement'] as String? ?? '',
      categoryOptionComboId:
          json['categoryOptionCombo'] as String? ?? '',
      orgUnitId: json['orgUnit'] as String? ?? '',
      period: json['period'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'dataElement': dataElementId,
        'categoryOptionCombo': categoryOptionComboId,
        'orgUnit': orgUnitId,
        'period': period,
        'value': value,
      };
}

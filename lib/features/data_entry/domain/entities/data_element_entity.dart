/// Represents a DHIS2 data element (a row in the data entry form)
class DataElementEntity {
  final String id;
  final String name;
  final String? shortName;
  final String valueType;
  final String? categoryComboId;
  final List<CategoryOptionCombo> categoryOptionCombos;

  /// Non-empty when the element has an option set: the server only
  /// accepts one of these option CODES as the value (E7621), so the
  /// cell renders a picker instead of free input.
  final List<OptionEntity> options;

  const DataElementEntity({
    required this.id,
    required this.name,
    this.shortName,
    this.valueType = 'NUMBER',
    this.categoryComboId,
    this.categoryOptionCombos = const [],
    this.options = const [],
  });

  String get displayName => shortName ?? name;
}

/// One choice of a data element's option set. [code] is what gets
/// stored and sent; [name] is what the user sees.
class OptionEntity {
  final String code;
  final String name;

  const OptionEntity({required this.code, required this.name});
}

/// Represents a column header in the data entry form
/// e.g. "Under 5 Years", "5 years and above"
class CategoryOptionCombo {
  final String id;
  final String name;
  final String? shortName;

  const CategoryOptionCombo({
    required this.id,
    required this.name,
    this.shortName,
  });

  String get displayName => shortName ?? name;
}

/// Represents a single data value entered by the user
class DataValueEntity {
  final String dataElementId;
  final String categoryOptionComboId;
  final String orgUnitId;
  final String period;
  String value;
  bool isModified;

  /// Server rejection text for this cell (null = not rejected).
  /// Cleared when the user edits the cell — saving re-queues it.
  String? syncError;

  DataValueEntity({
    required this.dataElementId,
    required this.categoryOptionComboId,
    required this.orgUnitId,
    required this.period,
    this.value = '',
    this.isModified = false,
    this.syncError,
  });

  String get key => '${dataElementId}_$categoryOptionComboId';

  bool get isEmpty => value.trim().isEmpty;
}

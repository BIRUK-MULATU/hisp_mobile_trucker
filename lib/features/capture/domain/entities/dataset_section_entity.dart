class DataSetSectionEntity {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;

  const DataSetSectionEntity({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSetSectionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

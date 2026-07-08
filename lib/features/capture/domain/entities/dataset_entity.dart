enum SyncStatus { synced, unsynced, pending }

class DataSetEntity {
  final String id;
  final String name;
  final String? shortName;
  final String? description;
  final String periodType;
  final SyncStatus syncStatus;
  final String? iconType; // determines which icon to show
  final DateTime? lastSynced;

  const DataSetEntity({
    required this.id,
    required this.name,
    this.shortName,
    this.description,
    required this.periodType,
    this.syncStatus = SyncStatus.unsynced,
    this.iconType,
    this.lastSynced,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

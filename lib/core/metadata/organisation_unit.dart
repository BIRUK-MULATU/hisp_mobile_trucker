import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('OrgUnit')
class OrgUnitsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get parentUid => text().nullable()();
  TextColumn get parentName => text().nullable()();
  TextColumn get path => text()();
  TextColumn get code => text().nullable()();
  TextColumn get openingDate => text().nullable()();
  TextColumn get closedDate => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  /// True for the roots of the logged-in user's capture tree
  /// (set from /api/me by the sync service, not by this resource).
  BoolColumn get isUserCaptureRoot =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

class OrgUnitResource extends MetadataResource<OrgUnit> {
  OrgUnitResource(super.db);

  @override
  String get resource => 'organisationUnits';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'parent[id,name]', 'path', 'code',
        'openingDate', 'closedDate', 'lastUpdated',
      ];

  @override
  TableInfo<Table, OrgUnit> get table => db.orgUnitsTable;

  @override
  Column<String> get uidColumn => db.orgUnitsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.orgUnitsTable.lastUpdated;

  @override
  Insertable<OrgUnit> companionFromJson(Map<String, dynamic> json) {
    return OrgUnitsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      parentUid: Value(json['parent']?['id'] as String?),
      parentName: Value(json['parent']?['name'] as String?),
      path: json['path'] as String? ?? '',
      code: Value(json['code'] as String?),
      openingDate: Value(json['openingDate'] as String?),
      closedDate: Value(json['closedDate'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  Future<List<OrgUnit>> getChildren(String parentUid) {
    return (db.select(db.orgUnitsTable)
          ..where((t) => t.parentUid.equals(parentUid))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<OrgUnit>> getCaptureRoots() {
    return (db.select(db.orgUnitsTable)
          ..where((t) => t.isUserCaptureRoot.equals(true)))
        .get();
  }
}

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';
import 'attribute.dart';

@DataClassName('DataElementGroup')
class DataElementGroupsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class DataElementGroupResource extends MetadataResource<DataElementGroup> {
  DataElementGroupResource(super.db);

  @override
  String get resource => 'dataElementGroups';

  @override
  List<String> get fields =>
      ['id', 'name', 'displayName', 'dataElements[id]', 'lastUpdated',
        attributeValuesField];

  @override
  TableInfo<Table, DataElementGroup> get table => db.dataElementGroupsTable;

  @override
  Column<String> get uidColumn => db.dataElementGroupsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.dataElementGroupsTable.lastUpdated;

  @override
  Insertable<DataElementGroup> companionFromJson(Map<String, dynamic> json) {
    return DataElementGroupsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested endpoint: also (re)writes the members link table.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final g in items) {
        final gUid = g['id'] as String;
        await db
            .into(db.dataElementGroupsTable)
            .insertOnConflictUpdate(companionFromJson(g));
        await (db.delete(db.attributeValuesTable)
              ..where((t) =>
                  t.objectType.equals('dataElementGroup') &
                  t.objectUid.equals(gUid)))
            .go();
        await (db.delete(db.dataElementGroupMembersTable)
              ..where((t) => t.dataElementGroupUid.equals(gUid)))
            .go();
        await db.batch((b) {
          writeAttributeValues(b, db, 'dataElementGroup', gUid, g);
          for (final de in (g['dataElements'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.dataElementGroupMembersTable,
              DataElementGroupMembersTableCompanion.insert(
                dataElementGroupUid: gUid,
                dataElementUid: de['id'] as String,
              ),
            );
          }
        });
      }
    });
  }

  Future<List<String>> dataElementUids(String groupUid) async {
    final rows = await (db.select(db.dataElementGroupMembersTable)
          ..where((t) => t.dataElementGroupUid.equals(groupUid)))
        .get();
    return [for (final r in rows) r.dataElementUid];
  }
}

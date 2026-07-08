import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';
import 'attribute.dart';

@DataClassName('DataElement')
class DataElementsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get formName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get valueType => text()();
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  TextColumn get optionSetUid => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class DataElementResource extends MetadataResource<DataElement> {
  DataElementResource(super.db);

  @override
  String get resource => 'dataElements';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'formName', 'description', 'valueType',
        'categoryCombo[id]', 'optionSet[id]', 'lastUpdated',
        attributeValuesField,
      ];

  @override
  TableInfo<Table, DataElement> get table => db.dataElementsTable;

  @override
  Column<String> get uidColumn => db.dataElementsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.dataElementsTable.lastUpdated;

  @override
  Insertable<DataElement> companionFromJson(Map<String, dynamic> json) {
    return DataElementsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      formName: (json['formName'] ?? json['name']) as String,
      description: Value(json['description'] as String?),
      valueType: json['valueType'] as String,
      categoryComboUid: json['categoryCombo']['id'] as String,
      optionSetUid: Value(json['optionSet']?['id'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Reverse of the group membership link: which data sets use this
  /// element (arriving side of data_set_elements).
  Future<List<String>> dataSetUids(String dataElementUid) async {
    final rows = await (db.select(db.dataSetElementsTable)
          ..where((t) => t.dataElementUid.equals(dataElementUid)))
        .get();
    return [for (final r in rows) r.dataSetUid];
  }

  /// Also (re)writes this data element's attribute values.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final de in items) {
        if (!isValid(de)) continue;
        final uid = de['id'] as String;
        await db.into(db.dataElementsTable)
            .insertOnConflictUpdate(companionFromJson(de));
        await (db.delete(db.attributeValuesTable)
              ..where((t) =>
                  t.objectType.equals('dataElement') & t.objectUid.equals(uid)))
            .go();
        await db.batch((b) =>
            writeAttributeValues(b, db, 'dataElement', uid, de));
      }
    });
  }
}

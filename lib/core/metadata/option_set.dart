import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('OptionSet')
class OptionSetsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get valueType => text()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class OptionSetResource extends MetadataResource<OptionSet> {
  OptionSetResource(super.db);

  @override
  String get resource => 'optionSets';

  @override
  List<String> get fields =>
      ['id', 'name', 'displayName', 'valueType', 'lastUpdated'];

  @override
  TableInfo<Table, OptionSet> get table => db.optionSetsTable;

  @override
  Column<String> get uidColumn => db.optionSetsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.optionSetsTable.lastUpdated;

  @override
  Insertable<OptionSet> companionFromJson(Map<String, dynamic> json) {
    return OptionSetsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      valueType: json['valueType'] as String? ?? 'TEXT',
      lastUpdated: lastUpdatedFrom(json),
    );
  }
}

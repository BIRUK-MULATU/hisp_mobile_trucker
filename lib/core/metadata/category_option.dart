import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('CategoryOption')
class CategoryOptionsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get shortName => text().nullable()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class CategoryOptionResource extends MetadataResource<CategoryOption> {
  CategoryOptionResource(super.db);

  @override
  String get resource => 'categoryOptions';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'shortName',
        'startDate', 'endDate', 'lastUpdated',
      ];

  @override
  TableInfo<Table, CategoryOption> get table => db.categoryOptionsTable;

  @override
  Column<String> get uidColumn => db.categoryOptionsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.categoryOptionsTable.lastUpdated;

  @override
  Insertable<CategoryOption> companionFromJson(Map<String, dynamic> json) {
    return CategoryOptionsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      shortName: Value(json['shortName'] as String?),
      startDate: Value(json['startDate'] as String?),
      endDate: Value(json['endDate'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }
}

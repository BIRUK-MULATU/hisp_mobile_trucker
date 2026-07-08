import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('Category')
class CategoriesTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get dataDimensionType => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class CategoryResource extends MetadataResource<Category> {
  CategoryResource(super.db);

  @override
  String get resource => 'categories';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'dataDimensionType',
        'categoryOptions[id]', 'lastUpdated',
      ];

  @override
  TableInfo<Table, Category> get table => db.categoriesTable;

  @override
  Column<String> get uidColumn => db.categoriesTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.categoriesTable.lastUpdated;

  @override
  Insertable<Category> companionFromJson(Map<String, dynamic> json) {
    return CategoriesTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      dataDimensionType: Value(json['dataDimensionType'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested endpoint: also (re)writes category_category_options.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final cat in items) {
        final catUid = cat['id'] as String;
        await db
            .into(db.categoriesTable)
            .insertOnConflictUpdate(companionFromJson(cat));
        await (db.delete(db.categoryCategoryOptionsTable)
              ..where((t) => t.categoryUid.equals(catUid)))
            .go();
        await db.batch((b) {
          var order = 0;
          for (final co in (cat['categoryOptions'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.categoryCategoryOptionsTable,
              CategoryCategoryOptionsTableCompanion.insert(
                categoryUid: catUid,
                categoryOptionUid: co['id'] as String,
                sortOrder: Value(order++),
              ),
            );
          }
        });
      }
    });
  }

  Future<List<String>> categoryOptionUids(String categoryUid) async {
    final rows = await (db.select(db.categoryCategoryOptionsTable)
          ..where((t) => t.categoryUid.equals(categoryUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return [for (final r in rows) r.categoryOptionUid];
  }
}

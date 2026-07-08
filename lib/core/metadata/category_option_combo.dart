import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('CategoryOptionCombo')
class CategoryOptionCombosTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class CategoryOptionComboResource
    extends MetadataResource<CategoryOptionCombo> {
  CategoryOptionComboResource(super.db);

  @override
  String get resource => 'categoryOptionCombos';

  @override
  List<String> get fields => [
        'id', 'name', 'categoryCombo[id]', 'categoryOptions[id]',
        'lastUpdated',
      ];

  @override
  TableInfo<Table, CategoryOptionCombo> get table =>
      db.categoryOptionCombosTable;

  @override
  Column<String> get uidColumn => db.categoryOptionCombosTable.uid;

  @override
  Column<DateTime>? get lastUpdatedColumn =>
      db.categoryOptionCombosTable.lastUpdated;

  @override
  Insertable<CategoryOptionCombo> companionFromJson(
      Map<String, dynamic> json) {
    return CategoryOptionCombosTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      categoryComboUid: json['categoryCombo']['id'] as String,
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested: also (re)writes which categoryOptions compose each COC.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await db.transaction(() async {
      for (final coc in items) {
        if (!isValid(coc)) continue;
        final uid = coc['id'] as String;
        await db
            .into(db.categoryOptionCombosTable)
            .insertOnConflictUpdate(companionFromJson(coc));
        await (db.delete(db.categoryOptionComboOptionsTable)
              ..where((t) => t.categoryOptionComboUid.equals(uid)))
            .go();
        await db.batch((b) {
          for (final co in (coc['categoryOptions'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.categoryOptionComboOptionsTable,
              CategoryOptionComboOptionsTableCompanion.insert(
                categoryOptionComboUid: uid,
                categoryOptionUid: co['id'] as String,
              ),
            );
          }
        });
      }
    });
  }

  /// FK lookup — cells of a combo in STORED order (arrival order; not
  /// necessarily display order). For display order use
  /// CategoryComboResource.orderedOptionCombos.
  Future<List<CategoryOptionCombo>> getByCategoryCombo(String comboUid) {
    return (db.select(db.categoryOptionCombosTable)
          ..where((t) => t.categoryComboUid.equals(comboUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// The categoryOption uids composing one COC (unordered set).
  Future<Set<String>> optionUidsOf(String cocUid) async {
    final rows = await (db.select(db.categoryOptionComboOptionsTable)
          ..where((t) => t.categoryOptionComboUid.equals(cocUid)))
        .get();
    return {for (final r in rows) r.categoryOptionUid};
  }
}

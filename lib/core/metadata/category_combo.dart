import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';
import 'category.dart';
import 'category_option_combo.dart';
import '../utils/app_logger.dart';

@DataClassName('CategoryCombo')
class CategoryCombosTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get dataDimensionType => text().nullable()();
  BoolColumn get skipTotal => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class CategoryComboResource extends MetadataResource<CategoryCombo> {
  CategoryComboResource(super.db);

  @override
  String get resource => 'categoryCombos';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'dataDimensionType', 'skipTotal',
        'categories[id]', 'lastUpdated',
      ];

  @override
  TableInfo<Table, CategoryCombo> get table => db.categoryCombosTable;

  @override
  Column<String> get uidColumn => db.categoryCombosTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.categoryCombosTable.lastUpdated;

  @override
  Insertable<CategoryCombo> companionFromJson(Map<String, dynamic> json) {
    return CategoryCombosTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      dataDimensionType: Value(json['dataDimensionType'] as String?),
      skipTotal: Value((json['skipTotal'] ?? false) as bool),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested endpoint: also (re)writes category_combo_categories.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final cc in items) {
        final ccUid = cc['id'] as String;
        await db
            .into(db.categoryCombosTable)
            .insertOnConflictUpdate(companionFromJson(cc));
        await (db.delete(db.categoryComboCategoriesTable)
              ..where((t) => t.categoryComboUid.equals(ccUid)))
            .go();
        await db.batch((b) {
          var order = 0;
          for (final cat in (cc['categories'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.categoryComboCategoriesTable,
              CategoryComboCategoriesTableCompanion.insert(
                categoryComboUid: ccUid,
                categoryUid: cat['id'] as String,
                sortOrder: Value(order++),
              ),
            );
          }
        });
      }
    });
  }

  Future<List<String>> categoryUids(String categoryComboUid) async {
    final rows = await (db.select(db.categoryComboCategoriesTable)
          ..where((t) => t.categoryComboUid.equals(categoryComboUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return [for (final r in rows) r.categoryUid];
  }

  /// Cells of a combo in DISPLAY order — derived, not stored.
  ///
  /// The order is the odometer of (category order) x (each category's
  /// option order): last category varies fastest, matching how DHIS2
  /// generates COCs. e.g. Sex[F,M] x Age[<15,15+] ->
  ///   F<15, F15+, M<15, M15+
  ///
  /// Malformed COCs (not exactly one option per category — rare, but
  /// real instances have them) sort to the END, logged, rather than
  /// breaking the form.
  Future<List<CategoryOptionCombo>> orderedOptionCombos(
      String categoryComboUid) async {
    final cocResource = CategoryOptionComboResource(db);
    final cocs = await cocResource.getByCategoryCombo(categoryComboUid);
    if (cocs.length <= 1) return cocs; // nothing to order (e.g. default)

    // Category order for this combo, and each category's option order.
    final catUids = await categoryUids(categoryComboUid);
    final categoryResource = CategoryResource(db);
    final optionRank = <String, Map<String, int>>{}; // catUid -> {optUid: pos}
    for (final catUid in catUids) {
      final opts = await categoryResource.categoryOptionUids(catUid);
      optionRank[catUid] = {
        for (var i = 0; i < opts.length; i++) opts[i]: i,
      };
    }

    // Build each COC's sort key: one option-position per category, in
    // category order. Missing/extra options -> null key -> sorts last.
    final keyed = <({CategoryOptionCombo coc, List<int>? key})>[];
    for (final coc in cocs) {
      final options = await cocResource.optionUidsOf(coc.uid);
      final key = <int>[];
      var ok = true;
      for (final catUid in catUids) {
        final ranks = optionRank[catUid]!;
        final match = options.where(ranks.containsKey);
        if (match.length != 1) {
          ok = false;
          break;
        }
        key.add(ranks[match.first]!);
      }
      keyed.add((coc: coc, key: ok ? key : null));
    }

    keyed.sort((a, b) {
      if (a.key == null && b.key == null) return 0;
      if (a.key == null) return 1; // malformed -> end
      if (b.key == null) return -1;
      for (var i = 0; i < a.key!.length; i++) {
        final c = a.key![i].compareTo(b.key![i]);
        if (c != 0) return c;
      }
      return 0;
    });

    final malformed = keyed.where((k) => k.key == null).length;
    if (malformed > 0) {
      log.w('[categoryCombos] $categoryComboUid: $malformed COC(s) with '
          'irregular option sets sorted to end');
    }
    return [for (final k in keyed) k.coc];
  }
}

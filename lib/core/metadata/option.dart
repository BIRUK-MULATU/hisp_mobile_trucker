import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('OptionItem')
class OptionsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Parent FK — options belong to exactly one set (no link table).
  TextColumn get optionSetUid => text().withLength(min: 11, max: 11)();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

/// Row class is OptionItem (not Option) — Option clashes with drift's
/// own Value/Option-style names and reads ambiguously in Dart.
class OptionResource extends MetadataResource<OptionItem> {
  OptionResource(super.db);

  @override
  String get resource => 'options';

  @override
  List<String> get fields => [
        'id', 'code', 'name', 'displayName', 'sortOrder',
        'optionSet[id]', 'lastUpdated',
      ];

  @override
  TableInfo<Table, OptionItem> get table => db.optionsTable;

  @override
  Column<String> get uidColumn => db.optionsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.optionsTable.lastUpdated;

  /// An option not belonging to any set is a server-side orphan —
  /// unreachable by any form, safe to skip.
  @override
  bool isValid(Map<String, dynamic> json) => json['optionSet']?['id'] != null;

  @override
  Insertable<OptionItem> companionFromJson(Map<String, dynamic> json) {
    return OptionsTableCompanion.insert(
      uid: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      sortOrder: Value((json['sortOrder'] ?? 0) as int),
      optionSetUid: json['optionSet']['id'] as String,
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// SQL-side FK lookup: the options of one set, in order.
  Future<List<OptionItem>> getByOptionSet(String optionSetUid) {
    return (db.select(db.optionsTable)
          ..where((t) => t.optionSetUid.equals(optionSetUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }
}
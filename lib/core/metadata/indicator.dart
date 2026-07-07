import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';
import 'attribute.dart';

@DataClassName('Indicator')
class IndicatorsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get numerator => text()();
  TextColumn get denominator => text()();
  TextColumn get description => text().nullable()();
  IntColumn get indicatorTypeFactor =>
      integer().withDefault(const Constant(1))();
  BoolColumn get annualized => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class IndicatorResource extends MetadataResource<Indicator> {
  IndicatorResource(super.db);

  @override
  String get resource => 'indicators';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'numerator', 'denominator',
        'description', 'annualized', 'indicatorType[factor]', 'lastUpdated',
        attributeValuesField,
      ];

  @override
  TableInfo<Table, Indicator> get table => db.indicatorsTable;

  @override
  Column<String> get uidColumn => db.indicatorsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.indicatorsTable.lastUpdated;

  @override
  Insertable<Indicator> companionFromJson(Map<String, dynamic> json) {
    return IndicatorsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      numerator: json['numerator'] as String? ?? '',
      denominator: json['denominator'] as String? ?? '1',
      description: Value(json['description'] as String?),
      indicatorTypeFactor:
          Value((json['indicatorType']?['factor'] ?? 1) as int),
      annualized: Value((json['annualized'] ?? false) as bool),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Also (re)writes this indicator's attribute values.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final ind in items) {
        if (!isValid(ind)) continue;
        final uid = ind['id'] as String;
        await db.into(db.indicatorsTable)
            .insertOnConflictUpdate(companionFromJson(ind));
        await (db.delete(db.attributeValuesTable)
              ..where((t) =>
                  t.objectType.equals('indicator') & t.objectUid.equals(uid)))
            .go();
        await db.batch((b) =>
            writeAttributeValues(b, db, 'indicator', uid, ind));
      }
    });
  }
}

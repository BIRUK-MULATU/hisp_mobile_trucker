import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('Section')
class SectionsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get dataSetUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class SectionResource extends MetadataResource<Section> {
  SectionResource(super.db);

  @override
  String get resource => 'sections';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'sortOrder', 'lastUpdated',
        'dataSet[id]',
        'dataElements[id]',
        'indicators[id]',
        'greyedFields[dataElement[id],categoryOptionCombo[id]]',
      ];

  @override
  TableInfo<Table, Section> get table => db.sectionsTable;

  @override
  Column<String> get uidColumn => db.sectionsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.sectionsTable.lastUpdated;

  @override
  Insertable<Section> companionFromJson(Map<String, dynamic> json) {
    return SectionsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      dataSetUid: json['dataSet']['id'] as String,
      sortOrder: Value((json['sortOrder'] ?? 0) as int),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested endpoint: also (re)writes section_data_elements,
  /// section_indicators, and section_grey_fields. One transaction.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final s in items) {
        final sUid = s['id'] as String;
        await db
            .into(db.sectionsTable)
            .insertOnConflictUpdate(companionFromJson(s));

        await (db.delete(db.sectionDataElementsTable)
              ..where((t) => t.sectionUid.equals(sUid)))
            .go();
        await (db.delete(db.sectionIndicatorsTable)
              ..where((t) => t.sectionUid.equals(sUid)))
            .go();
        await (db.delete(db.sectionGreyFieldsTable)
              ..where((t) => t.sectionUid.equals(sUid)))
            .go();

        await db.batch((b) {
          var deOrder = 0;
          for (final de in (s['dataElements'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.sectionDataElementsTable,
              SectionDataElementsTableCompanion.insert(
                sectionUid: sUid,
                dataElementUid: de['id'] as String,
                sortOrder: Value(deOrder++),
              ),
            );
          }
          var indOrder = 0;
          for (final ind in (s['indicators'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.sectionIndicatorsTable,
              SectionIndicatorsTableCompanion.insert(
                sectionUid: sUid,
                indicatorUid: ind['id'] as String,
                sortOrder: Value(indOrder++),
              ),
            );
          }
          for (final gf in (s['greyedFields'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.sectionGreyFieldsTable,
              SectionGreyFieldsTableCompanion.insert(
                sectionUid: sUid,
                dataElementUid: gf['dataElement']['id'] as String,
                categoryOptionComboUid:
                    gf['categoryOptionCombo']['id'] as String,
              ),
            );
          }
        });
      }
    });
  }

  /// Sections of a data set, in form order (FK lookup, SQL-side).
  Future<List<Section>> getByDataSet(String dataSetUid) {
    return (db.select(db.sectionsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<String>> dataElementUids(String sectionUid) async {
    final rows = await (db.select(db.sectionDataElementsTable)
          ..where((t) => t.sectionUid.equals(sectionUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return [for (final r in rows) r.dataElementUid];
  }

  Future<List<String>> indicatorUids(String sectionUid) async {
    final rows = await (db.select(db.sectionIndicatorsTable)
          ..where((t) => t.sectionUid.equals(sectionUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return [for (final r in rows) r.indicatorUid];
  }

  /// (element, cell) pairs this section disables — the entry form
  /// intersects these with its rendered cells.
  Future<List<({String dataElementUid, String categoryOptionComboUid})>>
      greyFieldsOf(String sectionUid) async {
    final rows = await (db.select(db.sectionGreyFieldsTable)
          ..where((t) => t.sectionUid.equals(sectionUid)))
        .get();
    return [
      for (final r in rows)
        (
          dataElementUid: r.dataElementUid,
          categoryOptionComboUid: r.categoryOptionComboUid,
        ),
    ];
  }
}

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';
import 'attribute.dart';

@DataClassName('DataSet')
class DataSetsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get periodType => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  IntColumn get openFuturePeriods =>
      integer().withDefault(const Constant(0))();
  IntColumn get expiryDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class DataSetResource extends MetadataResource<DataSet> {
  DataSetResource(super.db);

  @override
  String get resource => 'dataSets';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'periodType', 'version',
        'openFuturePeriods', 'expiryDays', 'lastUpdated',
        'categoryCombo[id]',
        attributeValuesField,
        // dataElement carries its own combo so the override can resolve:
        'dataSetElements[sortOrder,categoryCombo[id],dataElement[id,categoryCombo[id]]]',
        'organisationUnits[id]',
      ];

  @override
  TableInfo<Table, DataSet> get table => db.dataSetsTable;

  @override
  Column<String> get uidColumn => db.dataSetsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.dataSetsTable.lastUpdated;

  @override
  Insertable<DataSet> companionFromJson(Map<String, dynamic> json) {
    return DataSetsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      periodType: json['periodType'] as String,
      version: Value((json['version'] ?? 0) as int),
      categoryComboUid: json['categoryCombo']['id'] as String,
      openFuturePeriods: Value((json['openFuturePeriods'] ?? 0) as int),
      expiryDays: Value((json['expiryDays'] ?? 0) as int),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  /// Nested endpoint: also (re)writes data_set_elements — resolving the
  /// EFFECTIVE combo (override ?? element's own) at write time — and
  /// data_set_org_units. One transaction.
  ///
  /// NOTE: org unit assignments can be huge on national instances; the
  /// sync service should intersect with the user's capture org units
  /// before calling saveAll (fine as-is against a dev instance).
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await db.transaction(() async {
      for (final ds in items) {
        final dsUid = ds['id'] as String;
        await db
            .into(db.dataSetsTable)
            .insertOnConflictUpdate(companionFromJson(ds));

        await (db.delete(db.attributeValuesTable)
              ..where((t) =>
                  t.objectType.equals('dataSet') & t.objectUid.equals(dsUid)))
            .go();
        await (db.delete(db.dataSetElementsTable)
              ..where((t) => t.dataSetUid.equals(dsUid)))
            .go();
        await (db.delete(db.dataSetOrgUnitsTable)
              ..where((t) => t.dataSetUid.equals(dsUid)))
            .go();

        await db.batch((b) {
          writeAttributeValues(b, db, 'dataSet', dsUid, ds);
          var order = 0;
          for (final dse in (ds['dataSetElements'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            final de = dse['dataElement'] as Map<String, dynamic>;
            final effective = (dse['categoryCombo']?['id'] ??
                de['categoryCombo']['id']) as String;
            b.insert(
              db.dataSetElementsTable,
              DataSetElementsTableCompanion.insert(
                dataSetUid: dsUid,
                dataElementUid: de['id'] as String,
                categoryComboUid: effective,
                sortOrder: Value((dse['sortOrder'] as int?) ?? order),
              ),
            );
            order++;
          }
          for (final ou in (ds['organisationUnits'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            b.insert(
              db.dataSetOrgUnitsTable,
              DataSetOrgUnitsTableCompanion.insert(
                dataSetUid: dsUid,
                orgUnitUid: ou['id'] as String,
              ),
            );
          }
        });
      }
    });
  }

  /// Ordered element uids of one data set (business logic resolves
  /// with dataElementResource.getByIds).
  Future<List<String>> dataElementUids(String dataSetUid) async {
    final rows = await (db.select(db.dataSetElementsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return [for (final r in rows) r.dataElementUid];
  }

  /// EFFECTIVE combo uid per element for this data set — the form needs
  /// this, not the element's own combo.
  Future<Map<String, String>> effectiveComboByElement(
      String dataSetUid) async {
    final rows = await (db.select(db.dataSetElementsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid)))
        .get();
    return {for (final r in rows) r.dataElementUid: r.categoryComboUid};
  }

  /// Reverse lookup over the org unit link: which data sets apply to
  /// this facility. Returns full rows — it feeds the home screen.
  Future<List<DataSet>> getByOrgUnit(String orgUnitUid) async {
    final rows = await (db.select(db.dataSetOrgUnitsTable)
          ..where((t) => t.orgUnitUid.equals(orgUnitUid)))
        .get();
    return getByIds([for (final r in rows) r.dataSetUid]);
  }
}

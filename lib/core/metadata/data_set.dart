import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import 'metadata_resource.dart';
import 'attribute.dart';
import 'category.dart';
import 'category_combo.dart';
import 'category_option.dart';
import 'category_option_combo.dart';

@DataClassName('DataSet')
class DataSetsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get periodType => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  IntColumn get openFuturePeriods => integer().withDefault(const Constant(0))();
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
        'dataSetElements[sortOrder,compulsory,categoryCombo[id],dataElement[id,categoryCombo[id]]]',
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
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    // A national dataset is assigned to tens of thousands of org
    // units; only links into the locally-synced (capture-subtree)
    // org units are usable, so only those rows are kept. Org units
    // sync BEFORE data sets — see MetadataSyncService order.
    final localOuRows = await (db.selectOnly(db.orgUnitsTable)
          ..addColumns([db.orgUnitsTable.uid]))
        .get();
    final localOus = {
      for (final r in localOuRows) r.read(db.orgUnitsTable.uid)!,
    };

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
                compulsory: Value((dse['compulsory'] as bool?) ?? false),
              ),
            );
            order++;
          }
          for (final ou in (ds['organisationUnits'] as List? ?? [])
              .cast<Map<String, dynamic>>()) {
            final ouUid = ou['id'] as String;
            if (!localOus.contains(ouUid)) continue;
            b.insert(
              db.dataSetOrgUnitsTable,
              DataSetOrgUnitsTableCompanion.insert(
                dataSetUid: dsUid,
                orgUnitUid: ouUid,
              ),
            );
          }
        });
      }
    });
  }

  /// Org-unit assignment edits don't reliably bump a data set's
  /// lastUpdated, so the cheap id+lastUpdated delta can miss them and
  /// leave STALE assignment links — the capture flow then offers a
  /// facility a form whose completion the server refuses ("Data set
  /// not assigned to organisation unit"). Data sets are few, so a
  /// delta sync refetches ALL of them and mirrors deletions instead.
  @override
  Future<({int updated, int deleted})> syncDelta(ApiClient api) async {
    final items = await fetchJson(api);
    final remote = {for (final i in items) i['id'] as String};
    final localRows =
        await (db.selectOnly(table)..addColumns([uidColumn])).get();
    final removed = [
      for (final r in localRows)
        if (!remote.contains(r.read(uidColumn))) r.read(uidColumn)!,
    ];
    await saveAll(items);
    if (removed.isNotEmpty) {
      await deleteByIds(removed);
      await (db.delete(db.dataSetElementsTable)
            ..where((t) => t.dataSetUid.isIn(removed)))
          .go();
      await (db.delete(db.dataSetOrgUnitsTable)
            ..where((t) => t.dataSetUid.isIn(removed)))
          .go();
    }
    return (updated: items.length, deleted: removed.length);
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
  Future<Map<String, String>> effectiveComboByElement(String dataSetUid) async {
    final rows = await (db.select(db.dataSetElementsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid)))
        .get();
    return {for (final r in rows) r.dataElementUid: r.categoryComboUid};
  }

  /// DHIS2 `dataSetElement.compulsory` per element for this data set —
  /// a link-table property, so it's looked up the same way as
  /// [effectiveComboByElement].
  Future<Map<String, bool>> compulsoryByElement(String dataSetUid) async {
    final rows = await (db.select(db.dataSetElementsTable)
          ..where((t) => t.dataSetUid.equals(dataSetUid)))
        .get();
    return {for (final r in rows) r.dataElementUid: r.compulsory};
  }

  /// This DHIS2 instance classifies every data set with a custom
  /// "Dataset Category" attribute; a value of "Disease" marks a
  /// Disease Registration data set. Disease Registration and Routine
  /// data sets now share the same capture flow — this flag only
  /// drives which datasets get the disease styling (icon/AppBar).
  static const diseaseRegistrationCategoryAttribute = 'Dataset Category';
  static const diseaseRegistrationCategoryValue = 'Disease';

  /// Uids of data sets classified as Disease Registration.
  Future<Set<String>> diseaseRegistrationDataSetUids() async {
    final attrUid =
        await db.attributeUidByName(diseaseRegistrationCategoryAttribute);
    if (attrUid == null) return const {};
    final uids = await db.hostUidsByAttribute(
      objectType: 'dataSet',
      attributeUid: attrUid,
      value: diseaseRegistrationCategoryValue,
    );
    return uids.toSet();
  }

  /// Reverse lookup over the org unit link: every data set assigned
  /// to this facility, Routine and Disease Registration alike — it
  /// feeds the (single, merged) capture dataset list.
  Future<List<DataSet>> getByOrgUnit(String orgUnitUid) async {
    final rows = await (db.select(db.dataSetOrgUnitsTable)
          ..where((t) => t.orgUnitUid.equals(orgUnitUid)))
        .get();
    return getByIds([for (final r in rows) r.dataSetUid]);
  }

  /// This data set's OWN category combination (as opposed to a data
  /// element's — see [effectiveComboByElement]) — the DHIS2
  /// "category combination" the classic Data Entry app prompts for
  /// alongside period, e.g. Disease Registration's Department ×
  /// Outcome. Empty for the common case: a trivial/"default" combo,
  /// needing no user choice.
  ///
  /// A single COC is the normal signal for "trivial", but this
  /// instance's duplicate-'default'-COC defect (see
  /// [canonicalDefaultComboUid]) means a combo named 'default' can
  /// carry MULTIPLE locally-synced COCs — that must still collapse to
  /// no dimensions, or the capture flow wrongly prompts the user to
  /// "pick a combination" for what is really just the default, and
  /// whatever gets picked can resolve to a duplicate the web UI never
  /// shows the data under. So a combo named 'default' is always
  /// trivial, COC count aside.
  Future<List<CategoryDimension>> categoryDimensions(String dataSetId) async {
    final ds = await getById(dataSetId);
    if (ds == null) return const [];
    final comboUid = ds.categoryComboUid;

    final combo = await (db.select(db.categoryCombosTable)
          ..where((t) => t.uid.equals(comboUid)))
        .getSingleOrNull();
    if (combo != null && combo.name == 'default') return const [];

    final cocResource = CategoryOptionComboResource(db);
    final cocs = await cocResource.getByCategoryCombo(comboUid);
    if (cocs.length <= 1) return const [];

    final comboResource = CategoryComboResource(db);
    final catUids = await comboResource.categoryUids(comboUid);
    final categoryResource = CategoryResource(db);
    final categories = await categoryResource.getByIds(catUids);
    final categoryByUid = {for (final c in categories) c.uid: c};
    final optionResource = CategoryOptionResource(db);

    final dimensions = <CategoryDimension>[];
    for (final catUid in catUids) {
      final category = categoryByUid[catUid];
      if (category == null) continue; // category synced without its row
      final optionUids = await categoryResource.categoryOptionUids(catUid);
      final options = await optionResource.getByIds(optionUids);
      // getByIds is a plain `WHERE uid IN (...)` with no ORDER BY, so
      // it doesn't preserve optionUids' sortOrder — re-index against
      // it here so e.g. "OPD" before "IPD" survives to the UI.
      final optionByUid = {for (final o in options) o.uid: o};
      dimensions.add(CategoryDimension(
        uid: catUid,
        name: category.displayName,
        options: [
          for (final uid in optionUids)
            if (optionByUid[uid] case final o?)
              CategoryDimensionOption(uid: o.uid, name: o.displayName),
        ],
      ));
    }
    return dimensions;
  }

  /// The exact category option combo for one option chosen per
  /// dimension of [categoryDimensions] — order-independent (matched
  /// by the SET of chosen category option uids). Null if the
  /// selection doesn't resolve to any known combo (incomplete or
  /// metadata not yet synced).
  Future<String?> resolveCategoryOptionCombo(
    String dataSetId,
    Map<String, String> selections, // categoryUid -> categoryOptionUid
  ) async {
    final ds = await getById(dataSetId);
    if (ds == null || selections.isEmpty) return null;
    final wanted = selections.values.toSet();
    final cocResource = CategoryOptionComboResource(db);
    final cocs = await cocResource.getByCategoryCombo(ds.categoryComboUid);
    for (final coc in cocs) {
      final options = await cocResource.optionUidsOf(coc.uid);
      if (options.length == wanted.length && options.containsAll(wanted)) {
        return coc.uid;
      }
    }
    return null;
  }
}

/// One category of a data set's own category combination — e.g.
/// "Department" — with the options the user can pick from.
class CategoryDimension {
  final String uid;
  final String name;
  final List<CategoryDimensionOption> options;

  const CategoryDimension({
    required this.uid,
    required this.name,
    required this.options,
  });
}

class CategoryDimensionOption {
  final String uid;
  final String name;

  const CategoryDimensionOption({required this.uid, required this.name});
}

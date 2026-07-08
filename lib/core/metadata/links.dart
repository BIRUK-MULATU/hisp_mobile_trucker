import 'package:drift/drift.dart';

/// EVERY relationship (link) table lives here, once. No verbs, no
/// resources — schema only. This file IS the relationship map.
///
/// Rule: no Table class holding two uid columns may exist anywhere else.
/// Verbs over these tables live on the resources that use them
/// (both directions are legal — SQL relationships have no direction).

@DataClassName('DataSetElement')
class DataSetElementsTable extends Table {
  TextColumn get dataSetUid => text().withLength(min: 11, max: 11)();
  TextColumn get dataElementUid => text().withLength(min: 11, max: 11)();

  /// EFFECTIVE categoryCombo (override if present, else element's own),
  /// resolved at write time in DataSetResource.saveAll.
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dataSetUid, dataElementUid};
}

@DataClassName('DataSetOrgUnit')
class DataSetOrgUnitsTable extends Table {
  TextColumn get dataSetUid => text().withLength(min: 11, max: 11)();
  TextColumn get orgUnitUid => text().withLength(min: 11, max: 11)();

  @override
  Set<Column> get primaryKey => {dataSetUid, orgUnitUid};
}

@DataClassName('SectionDataElement')
class SectionDataElementsTable extends Table {
  TextColumn get sectionUid => text().withLength(min: 11, max: 11)();
  TextColumn get dataElementUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sectionUid, dataElementUid};
}

@DataClassName('SectionIndicator')
class SectionIndicatorsTable extends Table {
  TextColumn get sectionUid => text().withLength(min: 11, max: 11)();
  TextColumn get indicatorUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sectionUid, indicatorUid};
}

/// Grey fields are not entities: (element, cell) pairs a section
/// marks non-editable. Read together with the section's cells.
@DataClassName('SectionGreyField')
class SectionGreyFieldsTable extends Table {
  TextColumn get sectionUid => text().withLength(min: 11, max: 11)();
  TextColumn get dataElementUid => text().withLength(min: 11, max: 11)();
  TextColumn get categoryOptionComboUid =>
      text().withLength(min: 11, max: 11)();

  @override
  Set<Column> get primaryKey =>
      {sectionUid, dataElementUid, categoryOptionComboUid};
}

@DataClassName('DataElementGroupMember')
class DataElementGroupMembersTable extends Table {
  TextColumn get dataElementGroupUid => text().withLength(min: 11, max: 11)();
  TextColumn get dataElementUid => text().withLength(min: 11, max: 11)();

  @override
  Set<Column> get primaryKey => {dataElementGroupUid, dataElementUid};
}

@DataClassName('CategoryCategoryOption')
class CategoryCategoryOptionsTable extends Table {
  TextColumn get categoryUid => text().withLength(min: 11, max: 11)();
  TextColumn get categoryOptionUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {categoryUid, categoryOptionUid};
}

@DataClassName('CategoryComboCategory')
class CategoryComboCategoriesTable extends Table {
  TextColumn get categoryComboUid => text().withLength(min: 11, max: 11)();
  TextColumn get categoryUid => text().withLength(min: 11, max: 11)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {categoryComboUid, categoryUid};
}

/// Which categoryOptions compose each categoryOptionCombo. Pure fact,
/// no order column — display order is DERIVED at render time from the
/// combo's category order x each category's option order.
@DataClassName('CategoryOptionComboOption')
class CategoryOptionComboOptionsTable extends Table {
  TextColumn get categoryOptionComboUid =>
      text().withLength(min: 11, max: 11)();
  TextColumn get categoryOptionUid => text().withLength(min: 11, max: 11)();

  @override
  Set<Column> get primaryKey => {categoryOptionComboUid, categoryOptionUid};
}

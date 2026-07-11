import 'package:drift/drift.dart';

import 'connection/connection.dart' as connection;
import '../metadata/category.dart';
import '../metadata/category_combo.dart';
import '../metadata/category_option.dart';
import '../metadata/category_option_combo.dart';
import '../metadata/data_element.dart';
import '../metadata/data_element_group.dart';
import '../metadata/data_set.dart';
import '../metadata/indicator.dart';
import '../metadata/links.dart';
import '../metadata/option.dart';
import '../metadata/option_set.dart';
import '../metadata/organisation_unit.dart';
import '../metadata/section.dart';
import '../metadata/validation_rule.dart';

part 'app_database.g.dart';

/// Sync lifecycle of locally stored DATA (values, completions).
/// `draft` is device-only work: it is never pushed by any sync path
/// until the user completes the data set, which promotes it to
/// `pending`. Stored by index — only append new states.
enum SyncState { synced, pending, error, draft }

// ── Tables that stay global (not per-metadata-type) ─────────────────────

/// Cached /api/me.
@DataClassName('User')
class UsersTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get username => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {uid};
}

@DataClassName('AttributeDef')
class AttributesTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get valueType => text()();

  @override
  Set<Column> get primaryKey => {uid};
}

/// Generic attributeValues for ANY metadata object.
@DataClassName('AttributeValue')
class AttributeValuesTable extends Table {
  TextColumn get objectType => text()();
  TextColumn get objectUid => text().withLength(min: 11, max: 11)();
  TextColumn get attributeUid => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {objectType, objectUid, attributeUid};
}

@DataClassName('SyncInfoEntry')
class SyncInfoTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ── Data tables ──────────────────────────────────────────────────────────

@DataClassName('DataValue')
class DataValuesTable extends Table {
  TextColumn get dataElementUid => text().withLength(min: 11, max: 11)();
  TextColumn get period => text()();
  TextColumn get orgUnitUid => text().withLength(min: 11, max: 11)();
  TextColumn get categoryOptionComboUid =>
      text().withLength(min: 11, max: 11)();
  TextColumn get attributeOptionComboUid =>
      text().withLength(min: 11, max: 11)();

  TextColumn get storedBy => text().nullable()();
  TextColumn get value => text().nullable()();
  TextColumn get comment => text().nullable()();

  IntColumn get syncState => intEnum<SyncState>()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {
        dataElementUid,
        period,
        orgUnitUid,
        categoryOptionComboUid,
        attributeOptionComboUid,
      };
}

@DataClassName('CompleteDataSetRegistration')
class CompleteDataSetRegistrationsTable extends Table {
  TextColumn get dataSetUid => text().withLength(min: 11, max: 11)();
  TextColumn get period => text()();
  TextColumn get orgUnitUid => text().withLength(min: 11, max: 11)();
  TextColumn get attributeOptionComboUid =>
      text().withLength(min: 11, max: 11)();

  BoolColumn get completed => boolean()();
  TextColumn get storedBy => text().nullable()();
  DateTimeColumn get date => dateTime()();

  IntColumn get syncState => intEnum<SyncState>()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey =>
      {dataSetUid, period, orgUnitUid, attributeOptionComboUid};
}

// ─────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  // entities (one file each in core/metadata/)
  OrgUnitsTable,
  DataSetsTable,
  DataElementsTable,
  SectionsTable,
  IndicatorsTable,
  CategoriesTable,
  CategoryOptionsTable,
  CategoryCombosTable,
  CategoryOptionCombosTable,
  OptionSetsTable,
  OptionsTable,
  DataElementGroupsTable,
  ValidationRulesTable,
  // links (all in core/metadata/links.dart)
  DataSetElementsTable,
  DataSetOrgUnitsTable,
  SectionDataElementsTable,
  SectionIndicatorsTable,
  SectionGreyFieldsTable,
  DataElementGroupMembersTable,
  CategoryCategoryOptionsTable,
  CategoryComboCategoriesTable,
  CategoryOptionComboOptionsTable,
  // global
  UsersTable,
  AttributesTable,
  AttributeValuesTable,
  SyncInfoTable,
  // data
  DataValuesTable,
  CompleteDataSetRegistrationsTable,
])
class AppDatabase extends _$AppDatabase {
  /// One database FILE per logged-in user — [userKey] is a sanitized
  /// username. A user's metadata cache and (crucially) their pending
  /// unsynced data values are fully isolated from other users of the
  /// same device.
  AppDatabase.forUser(String userKey)
      : super(connection.openConnectionFor(sanitizeUserKey(userKey)));
  AppDatabase.forTesting(super.e);

  /// 'Nurse.Alem@HC' -> 'nurse_alem_hc' (safe as a filename).
  static String sanitizeUserKey(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
        onUpgrade: (m, from, to) async {},
      );

  /// Retention: delete data outside the allowed periods — ONLY synced
  /// rows; pending field data is kept forever.
  Future<int> purgeOutsideRetention(Set<String> allowedPeriods) async {
    final deleted = await (delete(dataValuesTable)
          ..where((t) =>
              t.syncState.equals(SyncState.synced.index) &
              t.period.isNotIn(allowedPeriods)))
        .go();
    await (delete(completeDataSetRegistrationsTable)
          ..where((t) =>
              t.syncState.equals(SyncState.synced.index) &
              t.period.isNotIn(allowedPeriods)))
        .go();
    return deleted;
  }

  Future<void> setSyncInfo(String key, String value) =>
      into(syncInfoTable).insertOnConflictUpdate(
          SyncInfoTableCompanion.insert(key: key, value: value));

  Future<String?> getSyncInfo(String key) async {
    final row = await (select(syncInfoTable)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }
}

/// True if this user has logged in on this device before (their
/// database exists) — the gate for allowing OFFLINE login.
Future<bool> userDatabaseExists(String userKey) =>
    connection.databaseExistsFor(AppDatabase.sanitizeUserKey(userKey));

/// Delete a user's database entirely — part of WIPE.
Future<void> deleteUserDatabase(String userKey) =>
    connection.deleteDatabaseFor(AppDatabase.sanitizeUserKey(userKey));

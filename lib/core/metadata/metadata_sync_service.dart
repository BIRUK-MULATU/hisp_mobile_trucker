import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'attribute.dart';
import 'category.dart';
import 'category_combo.dart';
import 'category_option.dart';
import 'category_option_combo.dart';
import 'data_element.dart';
import 'data_element_group.dart';
import 'data_set.dart';
import 'indicator.dart';
import 'option.dart';
import 'option_set.dart';
import 'organisation_unit.dart';
import 'section.dart';
import 'validation_rule.dart';

/// The ONLY place in the app that holds an ApiClient for metadata.
/// Everything else constructs resources with db alone and therefore
/// cannot reach the network — by construction.
///
/// Triggers (decided by the caller, not here):
///   - first login into an empty database
///   - the user's explicit "sync metadata" action
class MetadataSyncService {
  MetadataSyncService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  /// Runs syncAll on every resource in DEPENDENCY ORDER — parents
  /// before things that reference them, so uid references always land
  /// on rows that exist. Returns per-resource counts for the UI /
  /// sync log.
  ///
  /// Failure model: each step either completes its own transaction or
  /// throws — a network drop mid-sequence leaves earlier resources
  /// fully synced and later ones untouched (stale but consistent).
  /// The lastMetadataSync stamp is only written after a FULL pass.
  Future<Map<String, int>> syncMetadata() async {
    final counts = <String, int>{};

    // Full sync = mirror the server: clear metadata first so objects
    // deleted on the server disappear locally too. Data value tables,
    // users, and sync_info are NEVER touched here.
    await _clearMetadata();

    // ── 1. The category tower, bottom-up ──
    counts['categoryOptions'] = await CategoryOptionResource(_db).syncAll(_api);
    counts['categories'] = await CategoryResource(_db).syncAll(_api);
    counts['categoryCombos'] = await CategoryComboResource(_db).syncAll(_api);
    counts['categoryOptionCombos'] =
        await CategoryOptionComboResource(_db).syncAll(_api);

    // ── 2. Option machinery ──
    counts['optionSets'] = await OptionSetResource(_db).syncAll(_api);
    counts['options'] = await OptionResource(_db).syncAll(_api);

    // ── 2b. Attribute definitions (values ride inside their hosts) ──
    counts['attributes'] = await AttributeResource(_db).syncAll(_api);

    // ── 3. Elements and friends (reference combos + optionSets) ──
    counts['dataElements'] = await DataElementResource(_db).syncAll(_api);
    counts['indicators'] = await IndicatorResource(_db).syncAll(_api);
    counts['dataElementGroups'] =
        await DataElementGroupResource(_db).syncAll(_api);

    // ── 4. The user's capture roots from /me, then ONLY that org
    //       subtree — a facility user must not pull the national tree.
    final rootUids = await _fetchUserCaptureRoots();
    counts['organisationUnits'] =
        await (OrgUnitResource(_db)..captureRootUids = rootUids)
            .syncAll(_api);
    await _flagCaptureRoots(rootUids);

    // ── 5. Data sets and sections (reference nearly everything) ──
    counts['dataSets'] = await DataSetResource(_db).syncAll(_api);
    counts['sections'] = await SectionResource(_db).syncAll(_api);

    // ── 6. Validation rules (reference elements via expressions) ──
    counts['validationRules'] = await ValidationRuleResource(_db).syncAll(_api);

    await _db.setSyncInfo('lastMetadataSync', DateTime.now().toIso8601String());
    return counts;
  }

  /// Deletes ALL metadata + link tables so a full sync mirrors the
  /// server exactly. Explicitly EXCLUDES: dataValuesTable,
  /// completeDataSetRegistrationsTable (field data — never touched),
  /// usersTable (offline-login cache), syncInfoTable (sync bookkeeping).
  ///
  /// The list is explicit, not derived from allTables, precisely so a
  /// future table can't silently get wiped — adding a metadata table
  /// means consciously adding it here.
  Future<void> _clearMetadata() async {
    await _db.transaction(() async {
      final List<TableInfo> tables = [
        // entities
        _db.orgUnitsTable,
        _db.dataSetsTable,
        _db.dataElementsTable,
        _db.sectionsTable,
        _db.indicatorsTable,
        _db.categoriesTable,
        _db.categoryOptionsTable,
        _db.categoryCombosTable,
        _db.categoryOptionCombosTable,
        _db.optionSetsTable,
        _db.optionsTable,
        _db.dataElementGroupsTable,
        _db.validationRulesTable,
        _db.attributesTable,
        _db.attributeValuesTable,
        // links
        _db.dataSetElementsTable,
        _db.dataSetOrgUnitsTable,
        _db.sectionDataElementsTable,
        _db.sectionIndicatorsTable,
        _db.sectionGreyFieldsTable,
        _db.dataElementGroupMembersTable,
        _db.categoryCategoryOptionsTable,
        _db.categoryComboCategoriesTable,
        _db.categoryOptionComboOptionsTable,
      ];
      for (final t in tables) {
        await _db.delete(t).go();
      }
    });
    log.i('metadata cleared for full re-sync');
  }

  /// /api/me: caches the user row for offline login and returns the
  /// capture org unit uids — which also SCOPE the org unit sync.
  Future<List<String>> _fetchUserCaptureRoots() async {
    final res = await _api.get('/api/me.json', queryParameters: {
      'fields': 'id,username,displayName,organisationUnits[id]',
    });
    final me = res.data as Map<String, dynamic>;

    await _db.into(_db.usersTable).insertOnConflictUpdate(
          UsersTableCompanion.insert(
            uid: me['id'] as String,
            username: me['username'] as String? ?? '',
            displayName: me['displayName'] as String? ?? '',
          ),
        );

    return [
      for (final ou in (me['organisationUnits'] as List? ?? [])
          .cast<Map<String, dynamic>>())
        ou['id'] as String,
    ];
  }

  Future<void> _flagCaptureRoots(List<String> rootUids) async {
    // Clear old flags, set new ones (capture assignment can change).
    await (_db.update(_db.orgUnitsTable))
        .write(const OrgUnitsTableCompanion(isUserCaptureRoot: Value(false)));
    await (_db.update(_db.orgUnitsTable)..where((t) => t.uid.isIn(rootUids)))
        .write(const OrgUnitsTableCompanion(isUserCaptureRoot: Value(true)));
  }

  /// When the last full sync finished, or null if never.
  Future<DateTime?> lastSyncedAt() async {
    final v = await _db.getSyncInfo('lastMetadataSync');
    return v == null ? null : DateTime.tryParse(v);
  }

  /// LIGHT sync for login-while-online after the first: per resource,
  /// one id+lastUpdated request, then only changed objects are fetched
  /// and server-deleted ones removed. Same dependency order as the
  /// full sync. Returns per-resource (updated, deleted).
  Future<Map<String, ({int updated, int deleted})>> syncMetadataDelta() async {
    final r = <String, ({int updated, int deleted})>{};

    r['categoryOptions'] = await CategoryOptionResource(_db).syncDelta(_api);
    r['categories'] = await CategoryResource(_db).syncDelta(_api);
    r['categoryCombos'] = await CategoryComboResource(_db).syncDelta(_api);
    r['categoryOptionCombos'] =
        await CategoryOptionComboResource(_db).syncDelta(_api);
    r['optionSets'] = await OptionSetResource(_db).syncDelta(_api);
    r['options'] = await OptionResource(_db).syncDelta(_api);
    r['attributes'] = await AttributeResource(_db).syncDelta(_api);
    r['dataElements'] = await DataElementResource(_db).syncDelta(_api);
    r['indicators'] = await IndicatorResource(_db).syncDelta(_api);
    r['dataElementGroups'] =
        await DataElementGroupResource(_db).syncDelta(_api);
    final rootUids = await _fetchUserCaptureRoots();
    r['organisationUnits'] =
        await (OrgUnitResource(_db)..captureRootUids = rootUids)
            .syncDelta(_api);
    await _flagCaptureRoots(rootUids);
    r['dataSets'] = await DataSetResource(_db).syncDelta(_api);
    r['sections'] = await SectionResource(_db).syncDelta(_api);
    r['validationRules'] = await ValidationRuleResource(_db).syncDelta(_api);

    await _db.setSyncInfo('lastMetadataSync', DateTime.now().toIso8601String());
    return r;
  }
}

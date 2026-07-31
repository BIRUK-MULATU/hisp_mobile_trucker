import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
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

/// cc (a combo's categoryCombo) + cp (its categoryOption uids,
/// ';'-joined per the DHIS2 web API) for a non-default
/// categoryOptionCombo — the classic API has no single "give me this
/// exact combo" query param, so callers address it by its category
/// combo + option set instead. Empty for the default combo or when the
/// combo is missing from the local cache — the server then falls back
/// to its own default resolution (or, for audits, no combo filter at
/// all — see [ServerAuditService]).
Future<Map<String, String>> resolveCcCpParams(
    AppDatabase db, String cocUid) async {
  final coc = await (db.select(db.categoryOptionCombosTable)
        ..where((t) => t.uid.equals(cocUid)))
      .getSingleOrNull();
  if (coc == null || coc.name == 'default') return const {};
  final links = await (db.select(db.categoryOptionComboOptionsTable)
        ..where((t) => t.categoryOptionComboUid.equals(cocUid)))
      .get();
  return {
    'cc': coc.categoryComboUid,
    'cp': [for (final l in links) l.categoryOptionUid].join(';'),
  };
}

/// Sync-info key caching the resolved canonical default combo uid.
/// Shared between DataEntryRepositoryImpl (per-dataset resolution on
/// the UI paths) and the auto-sync push path below (dataset-agnostic
/// repair) so both agree on the same cached verdict.
const defaultAttributeOptionComboSyncInfoKey = 'defaultAttributeOptionCombo';

/// The confirmed default categoryOptionCombo uid for this HMIS
/// instance. The "resolve via the categoryCombo's declared list"
/// heuristic below turned out NOT to disambiguate reliably — the
/// server apparently lists more than one 'default'-named COC under
/// the same categoryCombo (or a dataset's own combo can be one of the
/// duplicates), so a live query can still land on a duplicate (e.g.
/// ed678csgTm8) instead of the real one. This uid was confirmed
/// directly against the server, so it is checked first and wins over
/// any dynamic resolution or stale cached verdict.
const canonicalDefaultComboUid = 'HllvX50cXC0';

/// True when this device's local metadata carries more than one
/// categoryOptionCombo named 'default' — the DHIS2 data-integrity
/// defect this instance has. A cheap local check so callers only pay
/// for a network round trip when a repair could possibly be needed.
Future<bool> hasDuplicateDefaultCombos(AppDatabase db) async {
  final rows = await (db.selectOnly(db.categoryOptionCombosTable,
          distinct: true)
        ..addColumns([db.categoryOptionCombosTable.uid])
        ..where(db.categoryOptionCombosTable.name.equals('default')))
      .get();
  return rows.length > 1;
}

/// The default categoryCombo ('default') is a single system-wide row —
/// unlike its COCs, which this instance has duplicated — so resolving
/// it needs no dataSet in hand. GETs it with its declared
/// categoryOptionCombos, persists both locally, and returns the uid of
/// the (unique) COC it declares. Null when offline or the response is
/// unusable.
Future<String?> fetchCanonicalDefaultCombo(
    AppDatabase db, ApiClient api) async {
  try {
    final res = await api.get('/api/categoryCombos.json', queryParameters: {
      'filter': 'name:eq:default',
      'fields': 'id,name,displayName,categoryOptionCombos[id,name]',
    });
    final combos = ((res.data as Map<String, dynamic>)['categoryCombos']
            as List? ??
        const [])
      .cast<Map<String, dynamic>>();
    if (combos.isEmpty) return null;
    final combo = combos.first;
    final cocs = (combo['categoryOptionCombos'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    if (cocs.isEmpty) return null;

    await db.into(db.categoryCombosTable).insertOnConflictUpdate(
          CategoryCombosTableCompanion.insert(
            uid: combo['id'] as String,
            name: combo['name'] as String,
            displayName: (combo['displayName'] ?? combo['name']) as String,
          ),
        );
    for (final coc in cocs) {
      await db.into(db.categoryOptionCombosTable).insertOnConflictUpdate(
            CategoryOptionCombosTableCompanion.insert(
              uid: coc['id'] as String,
              name: coc['name'] as String,
              categoryComboUid: combo['id'] as String,
            ),
          );
    }
    for (final coc in cocs) {
      if (coc['name'] == 'default') return coc['id'] as String;
    }
    return cocs.length == 1 ? cocs.first['id'] as String : null;
  } catch (e) {
    log.w('[categoryOptionCombo] canonical default combo fetch failed: $e');
    return null;
  }
}

/// The local COC uids named 'default' OTHER than [canonicalDefaultComboUid]
/// — exactly the uids a value must be remapped away from. Empty when
/// this instance's cached metadata has no duplicates (or none synced
/// locally yet). Shared by [remapDuplicateDefaultCombos] (existing rows)
/// and [DataValueSync]'s pull path (fresh rows arriving FROM the
/// server under a duplicate uid, which would otherwise silently
/// re-introduce the same defect on every sync).
Future<Set<String>> duplicateDefaultComboUids(AppDatabase db) async {
  final rows = await (db.select(db.categoryOptionCombosTable)
        ..where(
            (t) => t.name.equals('default') & t.uid.equals(canonicalDefaultComboUid).not()))
      .get();
  return {for (final r in rows) r.uid};
}

/// One-time repair after the authoritative default COC is known: rows
/// stored under one of the OTHER local COCs named 'default' (the
/// duplicates) are rewritten to [canonical]. Their composite key is
/// changing, so anything the server has already seen under the OLD
/// key — 'synced' rows, not just 'error' ones — goes back to pending:
/// the server never actually stored the value under [canonical], so
/// only a fresh push under the corrected key makes it reach the web
/// UI. Draft rows are left as drafts (not sent yet by design).
/// Duplicate-keyed leftovers give way to an existing canonical row.
/// Returns the number of dataValue + completion rows touched.
Future<int> remapDuplicateDefaultCombos(
    AppDatabase db, String canonical) async {
  final dupeRows = await (db.select(db.categoryOptionCombosTable)
        ..where(
            (t) => t.name.equals('default') & t.uid.equals(canonical).not()))
      .get();
  if (dupeRows.isEmpty) return 0;
  final dupes = [for (final d in dupeRows) d.uid];

  final values = await (db.select(db.dataValuesTable)
        ..where((t) =>
            t.attributeOptionComboUid.isIn(dupes) |
            t.categoryOptionComboUid.isIn(dupes)))
      .get();
  for (final v in values) {
    await (db.delete(db.dataValuesTable)
          ..where((t) =>
              t.dataElementUid.equals(v.dataElementUid) &
              t.period.equals(v.period) &
              t.orgUnitUid.equals(v.orgUnitUid) &
              t.categoryOptionComboUid.equals(v.categoryOptionComboUid) &
              t.attributeOptionComboUid.equals(v.attributeOptionComboUid)))
        .go();
    final needsRepush =
        v.syncState == SyncState.error || v.syncState == SyncState.synced;
    await db.into(db.dataValuesTable).insert(
          v.toCompanion(false).copyWith(
            categoryOptionComboUid: Value(
                dupes.contains(v.categoryOptionComboUid)
                    ? canonical
                    : v.categoryOptionComboUid),
            attributeOptionComboUid: Value(
                dupes.contains(v.attributeOptionComboUid)
                    ? canonical
                    : v.attributeOptionComboUid),
            syncState: needsRepush
                ? const Value(SyncState.pending)
                : Value(v.syncState),
            syncError:
                needsRepush ? const Value(null) : Value(v.syncError),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  final regs = await (db.select(db.completeDataSetRegistrationsTable)
        ..where((t) => t.attributeOptionComboUid.isIn(dupes)))
      .get();
  for (final r in regs) {
    await (db.delete(db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(r.dataSetUid) &
              t.period.equals(r.period) &
              t.orgUnitUid.equals(r.orgUnitUid) &
              t.attributeOptionComboUid.equals(r.attributeOptionComboUid)))
        .go();
    await db.into(db.completeDataSetRegistrationsTable).insert(
          r.toCompanion(false).copyWith(
            attributeOptionComboUid: Value(canonical),
            syncState: (r.syncState == SyncState.error ||
                    r.syncState == SyncState.synced)
                ? const Value(SyncState.pending)
                : Value(r.syncState),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  if (values.isNotEmpty || regs.isNotEmpty) {
    log.i('[categoryOptionCombo] remapped ${values.length} value(s), '
        '${regs.length} registration(s) from duplicate default COCs '
        'to $canonical');
  }
  return values.length + regs.length;
}

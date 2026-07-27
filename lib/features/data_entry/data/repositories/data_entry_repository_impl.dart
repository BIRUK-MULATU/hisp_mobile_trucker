import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/data/completeness.dart';
import '../../../../core/data/data_value_push.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/data/data_value_sync.dart';
import '../../../../core/data/validation_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/metadata/category_combo.dart';
import '../../../../core/metadata/data_element.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/metadata/option.dart';
import '../../../../core/metadata/section.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/data_element_entity.dart' as entity;
import '../../domain/repositories/data_entry_repository.dart';

/// OFFLINE-FIRST data entry on the per-user SQLite database.
///
/// Reads come from the local store (form metadata from the synced
/// metadata tables, values from data_values). Writes land locally as
/// `draft` — device-only, invisible to every sync path — until the
/// user completes the data set, which promotes them to `pending` and
/// pushes. When online, opening a form first runs
/// DataValueSync.syncForm (pull + conflict-resolve + push) so the
/// cells show fresh server state — failure of that step is never
/// fatal, the local data simply stands.
class DataEntryRepositoryImpl implements DataEntryRepository {
  final SessionService _session;
  final NetworkInfo _networkInfo;

  DataEntryRepositoryImpl({
    SessionService? session,
    NetworkInfo? networkInfo,
  })  : _session = session ?? AppSession.instance.service,
        _networkInfo = networkInfo ?? ConnectivityNetworkInfo();

  AppDatabase get _db => _session.db;

  @override
  Future<List<entity.DataElementEntity>> getDataElements({
    required String dataSetId,
    String? sectionId,
  }) async {
    final uids = sectionId == null
        ? await DataSetResource(_db).dataElementUids(dataSetId)
        : await SectionResource(_db).dataElementUids(sectionId);
    if (uids.isEmpty) {
      throw const CacheException(
          message: 'Form metadata is not on this device yet — '
              'sync while online first.');
    }

    final effectiveCombo =
        await DataSetResource(_db).effectiveComboByElement(dataSetId);
    final rows = await DataElementResource(_db).getByIds(uids);
    final byUid = {for (final r in rows) r.uid: r};
    final comboResource = CategoryComboResource(_db);

    // COC lists repeat heavily across elements — resolve each combo once.
    final cocsByCombo = <String, List<CategoryOptionCombo>>{};
    // Same for option sets: many elements share one set.
    final optionResource = OptionResource(_db);
    final optionsBySet = <String, List<entity.OptionEntity>>{};

    final result = <entity.DataElementEntity>[];
    for (final uid in uids) {
      final row = byUid[uid];
      if (row == null) continue; // link without its element: skip
      final comboUid = effectiveCombo[uid] ?? row.categoryComboUid;
      var cocs = cocsByCombo[comboUid] ??=
          await comboResource.orderedOptionCombos(comboUid);
      // Empty = combo synced without its COCs; all-'default' = the
      // default combo, where the server carries DUPLICATE default
      // COCs. Either way, collapse to the single authoritative
      // default COC — never invent an id or let a duplicate through,
      // the server only accepts the declared uid (HllvX50cXC0 here).
      if (cocs.isEmpty || cocs.every((c) => c.name == 'default')) {
        final defaultUid = await _defaultAttributeOptionCombo(dataSetId);
        cocs = cocsByCombo[comboUid] = [
          CategoryOptionCombo(
            uid: defaultUid,
            name: 'default',
            categoryComboUid: comboUid,
            sortOrder: 0,
          ),
        ];
      }
      final optionSetUid = row.optionSetUid;
      final options = optionSetUid == null
          ? const <entity.OptionEntity>[]
          : optionsBySet[optionSetUid] ??= [
              for (final o in await optionResource.getByOptionSet(optionSetUid))
                entity.OptionEntity(code: o.code, name: o.displayName),
            ];
      result.add(entity.DataElementEntity(
        id: row.uid,
        name: row.formName.isNotEmpty ? row.formName : row.displayName,
        valueType: row.valueType,
        categoryComboId: comboUid,
        categoryOptionCombos: [
          for (final coc in cocs)
            entity.CategoryOptionCombo(id: coc.uid, name: coc.name),
        ],
        options: options,
      ));
    }
    if (result.isEmpty) {
      throw const CacheException(
          message: 'Form metadata is not on this device yet — '
              'sync while online first.');
    }
    return result;
  }

  @override
  Future<List<entity.DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);
    final elementUids = await DataSetResource(_db).dataElementUids(dataSetId);

    // Fresh server state when reachable; purely best-effort.
    final api = AppSession.instance.api;
    if (api != null && await _networkInfo.isConnected) {
      try {
        await DataValueSync(_db, api).syncForm(
          dataSetUid: dataSetId,
          period: period,
          orgUnitUid: orgUnitId,
          dataElementUids: elementUids,
          attributeOptionComboUid: aoc,
        );
      } catch (e) {
        log.w('[dataEntry] form sync failed, using local data: $e');
      }
    }

    final rows = await DataValueStore(_db).valuesForForm(
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
      dataElementUids: elementUids,
    );
    return [
      for (final r in rows)
        entity.DataValueEntity(
          dataElementId: r.dataElementUid,
          categoryOptionComboId: r.categoryOptionComboUid,
          orgUnitId: r.orgUnitUid,
          period: r.period,
          value: r.value ?? '',
          syncError: r.syncState == SyncState.error ? r.syncError : null,
        ),
    ];
  }

  @override
  Future<void> saveDataValues({
    required List<entity.DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);
    final store = DataValueStore(_db);
    final storedBy = await SecureStorage().getUsername();

    // Drafts by design: saving keeps the values on this device only.
    // They go to the server when the user completes the data set
    // (completeDataSet promotes + pushes).
    for (final v in dataValues) {
      await store.setValue(
        dataElementUid: v.dataElementId,
        period: period,
        orgUnitUid: orgUnitId,
        categoryOptionComboUid: v.categoryOptionComboId,
        attributeOptionComboUid: aoc,
        value: v.value.trim().isEmpty ? null : v.value.trim(),
        storedBy: storedBy,
        draft: true,
      );
    }
  }

  @override
  Future<List<ValidationViolation>> validateDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);
    return ValidationService(_db).validateForm(
      dataSetUid: dataSetId,
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
    );
  }

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);

    // Completing is the sign-off: the form's drafts become sendable.
    final elementUids = await DataSetResource(_db).dataElementUids(dataSetId);
    await DataValueStore(_db).promoteDrafts(
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
      dataElementUids: elementUids,
    );

    await CompletenessStore(_db).setComplete(
      dataSetUid: dataSetId,
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
      completed: true,
      storedBy: await SecureStorage().getUsername(),
    );

    // Best-effort send; offline everything stays pending and the
    // auto-sync doors (transition/login/heartbeat) pick it up later.
    final api = AppSession.instance.api;
    if (api != null && await _networkInfo.isConnected) {
      unawaited(_pushAfterComplete(api).catchError((Object e) {
        log.w('[dataEntry] post-complete push failed, stays pending: $e');
      }));
    }
  }

  @override
  Future<bool> isCompleted({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);
    final reg = await CompletenessStore(_db).statusOf(
      dataSetUid: dataSetId,
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
    );
    return reg?.completed ?? false;
  }

  @override
  Future<void> uncompleteDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo(dataSetId);

    // completed=false is its own pending fact: the push turns it into
    // a DELETE against completeDataSetRegistrations. Drafts stay
    // drafts — reopening is exactly the state where the user keeps
    // editing before signing off again.
    await CompletenessStore(_db).setComplete(
      dataSetUid: dataSetId,
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
      completed: false,
      storedBy: await SecureStorage().getUsername(),
    );

    final api = AppSession.instance.api;
    if (api != null && await _networkInfo.isConnected) {
      unawaited(CompletenessSync(_db, api).pushPending().catchError((Object e) {
        log.w('[dataEntry] un-complete push failed, stays pending: $e');
        return 0;
      }));
    }
  }

  /// Values first, completion second — the server should not report a
  /// period complete before the numbers behind it have arrived.
  Future<void> _pushAfterComplete(ApiClient api) async {
    final store = DataValueStore(_db);
    final pending = await store.pendingValues();
    if (pending.isNotEmpty) {
      await pushDataValueBatch(
        api: api,
        store: store,
        values: pending,
        logTag: 'dataEntry',
      );
    }
    await CompletenessSync(_db, api).pushPending();
  }

  // ── internals ──────────────────────────────────────────────────────

  static const _defaultCocKey = 'defaultAttributeOptionCombo';

  /// The UI doesn't support attribute category combos (neither did the
  /// old remote flow, which let the server default them) — everything
  /// is stored under the instance's default attributeOptionCombo.
  ///
  /// The instance carries DUPLICATE COCs named 'default' (a known
  /// DHIS2 data-integrity defect — staging has three), so a name
  /// lookup can land on one the server rejects for writing (E7613).
  /// The authoritative default is the COC the default categoryCombo
  /// itself DECLARES, so resolution is: cached verdict → the data
  /// set's categoryCombo from the API → local name lookup as the
  /// offline-only last resort.
  Future<String> _defaultAttributeOptionCombo(String dataSetId) async {
    final cached = await _db.getSyncInfo(_defaultCocKey);
    if (cached != null) return cached;

    final fetched = await _fetchDefaultComboFromDataSet(dataSetId);
    if (fetched != null) {
      await _db.setSyncInfo(_defaultCocKey, fetched);
      // Values captured before this verdict may sit under a duplicate
      // 'default' uid — move them so they become pushable.
      await _remapDuplicateDefaults(fetched);
      return fetched;
    }

    final rows = await (_db.select(_db.categoryOptionCombosTable)
          ..where((t) => t.name.equals('default'))
          ..limit(1))
        .get();
    if (rows.isNotEmpty) return rows.first.uid;

    throw const CacheException(
        message: 'Metadata is not on this device yet — '
            'sync while online first.');
  }

  /// One-time repair after the authoritative default COC is known:
  /// rows stored under one of the OTHER local COCs named 'default'
  /// (the duplicates) are rewritten to [canonical]; rows the server
  /// already rejected for it go back to pending so the next push
  /// retries them. Duplicate-keyed leftovers give way to an existing
  /// canonical row.
  Future<void> _remapDuplicateDefaults(String canonical) async {
    final dupeRows = await (_db.select(_db.categoryOptionCombosTable)
          ..where(
              (t) => t.name.equals('default') & t.uid.equals(canonical).not()))
        .get();
    if (dupeRows.isEmpty) return;
    final dupes = [for (final d in dupeRows) d.uid];

    final values = await (_db.select(_db.dataValuesTable)
          ..where((t) =>
              t.attributeOptionComboUid.isIn(dupes) |
              t.categoryOptionComboUid.isIn(dupes)))
        .get();
    for (final v in values) {
      await (_db.delete(_db.dataValuesTable)
            ..where((t) =>
                t.dataElementUid.equals(v.dataElementUid) &
                t.period.equals(v.period) &
                t.orgUnitUid.equals(v.orgUnitUid) &
                t.categoryOptionComboUid.equals(v.categoryOptionComboUid) &
                t.attributeOptionComboUid.equals(v.attributeOptionComboUid)))
          .go();
      final wasRejected = v.syncState == SyncState.error;
      await _db.into(_db.dataValuesTable).insert(
            v.toCompanion(false).copyWith(
              categoryOptionComboUid: Value(
                  dupes.contains(v.categoryOptionComboUid)
                      ? canonical
                      : v.categoryOptionComboUid),
              attributeOptionComboUid: Value(
                  dupes.contains(v.attributeOptionComboUid)
                      ? canonical
                      : v.attributeOptionComboUid),
              syncState:
                  wasRejected ? const Value(SyncState.pending) : Value(v.syncState),
              syncError: wasRejected ? const Value(null) : Value(v.syncError),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }

    final regs = await (_db.select(_db.completeDataSetRegistrationsTable)
          ..where((t) => t.attributeOptionComboUid.isIn(dupes)))
        .get();
    for (final r in regs) {
      await (_db.delete(_db.completeDataSetRegistrationsTable)
            ..where((t) =>
                t.dataSetUid.equals(r.dataSetUid) &
                t.period.equals(r.period) &
                t.orgUnitUid.equals(r.orgUnitUid) &
                t.attributeOptionComboUid.equals(r.attributeOptionComboUid)))
          .go();
      await _db.into(_db.completeDataSetRegistrationsTable).insert(
            r.toCompanion(false).copyWith(
              attributeOptionComboUid: Value(canonical),
              syncState: r.syncState == SyncState.error
                  ? const Value(SyncState.pending)
                  : Value(r.syncState),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }

    if (values.isNotEmpty || regs.isNotEmpty) {
      log.i('[dataEntry] remapped ${values.length} value(s), '
          '${regs.length} registration(s) from duplicate default COCs '
          'to $canonical');
    }
  }

  /// GET the data set's categoryCombo (with its COCs) and persist both
  /// locally, so the next resolution works offline. Returns the default
  /// COC uid, or null when offline / the response has no usable combo.
  Future<String?> _fetchDefaultComboFromDataSet(String dataSetId) async {
    final api = AppSession.instance.api;
    if (api == null || !await _networkInfo.isConnected) return null;
    try {
      final res = await api.get('/api/dataSets/$dataSetId.json',
          queryParameters: {
            'fields': 'categoryCombo[id,name,displayName,'
                'categoryOptionCombos[id,name]]',
          });
      final combo = (res.data as Map<String, dynamic>)['categoryCombo']
          as Map<String, dynamic>?;
      if (combo == null) return null;
      final cocs = (combo['categoryOptionCombos'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      if (cocs.isEmpty) return null;

      await _db.into(_db.categoryCombosTable).insertOnConflictUpdate(
            CategoryCombosTableCompanion.insert(
              uid: combo['id'] as String,
              name: combo['name'] as String,
              displayName: (combo['displayName'] ?? combo['name']) as String,
            ),
          );
      for (final coc in cocs) {
        await _db.into(_db.categoryOptionCombosTable).insertOnConflictUpdate(
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
      // A dataset with a non-default attribute combo: only usable as a
      // default when it is unambiguous.
      return cocs.length == 1 ? cocs.first['id'] as String : null;
    } catch (e) {
      log.w('[dataEntry] default combo fetch failed: $e');
      return null;
    }
  }
}

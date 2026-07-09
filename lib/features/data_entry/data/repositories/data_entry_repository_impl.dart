import 'dart:async';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/data/completeness.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/data/data_value_sync.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/metadata/category_combo.dart';
import '../../../../core/metadata/data_element.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/metadata/section.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/data_element_entity.dart' as entity;
import '../../domain/repositories/data_entry_repository.dart';

/// OFFLINE-FIRST data entry on the per-user SQLite database.
///
/// Reads come from the local store (form metadata from the synced
/// metadata tables, values from data_values). Writes land locally as
/// `pending` and are pushed by the sync layer. When online, opening a
/// form first runs DataValueSync.syncForm (pull + conflict-resolve +
/// push) so the cells show fresh server state — failure of that step
/// is never fatal, the local data simply stands.
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

    final result = <entity.DataElementEntity>[];
    for (final uid in uids) {
      final row = byUid[uid];
      if (row == null) continue; // link without its element: skip
      final comboUid = effectiveCombo[uid] ?? row.categoryComboUid;
      final cocs = cocsByCombo[comboUid] ??=
          await comboResource.orderedOptionCombos(comboUid);
      result.add(entity.DataElementEntity(
        id: row.uid,
        name: row.formName.isNotEmpty ? row.formName : row.displayName,
        valueType: row.valueType,
        categoryComboId: comboUid,
        categoryOptionCombos: [
          for (final coc in cocs)
            entity.CategoryOptionCombo(id: coc.uid, name: coc.name),
        ],
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
    final aoc = await _defaultAttributeOptionCombo();
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
    final aoc = await _defaultAttributeOptionCombo();
    final store = DataValueStore(_db);
    final storedBy = await SecureStorage().getUsername();

    for (final v in dataValues) {
      await store.setValue(
        dataElementUid: v.dataElementId,
        period: period,
        orgUnitUid: orgUnitId,
        categoryOptionComboUid: v.categoryOptionComboId,
        attributeOptionComboUid: aoc,
        value: v.value.trim().isEmpty ? null : v.value.trim(),
        storedBy: storedBy,
      );
    }

    // Saved locally = saved. Try to get it to the server right away,
    // but never let that attempt fail the save.
    final api = AppSession.instance.api;
    if (api != null && await _networkInfo.isConnected) {
      final elementUids =
          await DataSetResource(_db).dataElementUids(dataSetId);
      unawaited(DataValueSync(_db, api)
          .syncForm(
            dataSetUid: dataSetId,
            period: period,
            orgUnitUid: orgUnitId,
            dataElementUids: elementUids,
            attributeOptionComboUid: aoc,
          )
          .catchError((Object e) {
        log.w('[dataEntry] post-save push failed, values stay pending: $e');
        return const DataValueSyncResult(pulled: false);
      }));
    }
  }

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final aoc = await _defaultAttributeOptionCombo();
    await CompletenessStore(_db).setComplete(
      dataSetUid: dataSetId,
      period: period,
      orgUnitUid: orgUnitId,
      attributeOptionComboUid: aoc,
      completed: true,
      storedBy: await SecureStorage().getUsername(),
    );

    final api = AppSession.instance.api;
    if (api != null && await _networkInfo.isConnected) {
      unawaited(
          CompletenessSync(_db, api).pushPending().catchError((Object e) {
        log.w('[dataEntry] completion push failed, stays pending: $e');
        return 0;
      }));
    }
  }

  // ── internals ──────────────────────────────────────────────────────

  /// The UI doesn't support attribute category combos (neither did the
  /// old remote flow, which let the server default them) — everything
  /// is stored under the instance's default attributeOptionCombo.
  Future<String> _defaultAttributeOptionCombo() async {
    final rows = await (_db.select(_db.categoryOptionCombosTable)
          ..where((t) => t.name.equals('default'))
          ..limit(1))
        .get();
    if (rows.isEmpty) {
      throw const CacheException(
          message: 'Metadata is not on this device yet — '
              'sync while online first.');
    }
    return rows.first.uid;
  }
}

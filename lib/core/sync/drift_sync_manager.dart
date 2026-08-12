import 'dart:async';

import '../../features/visualization/data/repositories/chart_repository_impl.dart';
import '../../features/visualization/domain/entities/chart_config.dart';
import '../auth/app_session.dart';
import '../data/completeness.dart';
import '../data/data_value_push.dart';
import '../data/data_value_store.dart';
import '../database/app_database.dart';
import '../metadata/category_option_combo.dart';
import '../metadata/metadata_sync_service.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'sync_manager.dart';

/// The real [SyncManager], on top of the offline layer.
///
/// pushPending: uploads every locally-queued write — all pending data
/// values in ONE dataValueSets import (each value carries its full
/// identity, so no dataSet grouping is needed) plus pending
/// completions. Values the server rejects flip to error state with the
/// conflict text; transport failures leave everything pending for the
/// next attempt. Safe to call repeatedly.
///
/// pullLatest: metadata delta sync (per-resource id+lastUpdated diff).
/// Data values are pulled per form when a form is opened, not here.
class DriftSyncManager implements SyncManager {
  DriftSyncManager._();
  static final DriftSyncManager instance = DriftSyncManager._();

  final _syncing = StreamController<bool>.broadcast();
  bool _running = false;

  @override
  Stream<bool> get isSyncing => _syncing.stream;

  @override
  Future<void> pushPending() async {
    final session = AppSession.instance;
    final api = session.api;
    if (!session.isLoggedIn || api == null || _running) return;

    _running = true;
    _syncing.add(true);
    try {
      final db = session.service.db;
      // A full-offline capture session (enter → complete → push, all
      // before the form is ever reopened) can leave pending rows tagged
      // with a duplicate 'default' COC — the UI-side repair in
      // DataEntryRepositoryImpl only runs when a dataset's form is
      // opened, which this blind auto-sync push never does. Fix that up
      // first so those rows land on the server under the uid it
      // actually recognizes.
      await _repairDuplicateDefaultCombos(db, api);
      final pushed = await _pushDataValues(db);
      final completions = await CompletenessSync(db, api).pushPending();
      final charts = await ChartRepositoryImpl(session: session.service, api: api)
          .pushPendingCharts();
      if (pushed > 0 || completions > 0 || charts > 0) {
        log.i('[autoSync] pushed $pushed values, $completions completions, '
            '$charts charts');
      }
    } finally {
      _running = false;
      _syncing.add(false);
    }
  }

  @override
  Future<bool> hasPendingWork() async {
    final session = AppSession.instance;
    if (!session.isLoggedIn) return false;
    final db = session.service.db;

    if (await DataValueStore(db).pendingCount() > 0) return true;
    if ((await CompletenessStore(db).pending()).isNotEmpty) return true;

    final api = session.api;
    if (api != null) {
      final charts =
          await ChartRepositoryImpl(session: session.service, api: api)
              .getSavedCharts();
      if (charts.any((c) => c.syncState != ChartSyncState.synced)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> pullLatest() async {
    final session = AppSession.instance;
    final api = session.api;
    if (!session.isLoggedIn || api == null) return;
    // The first full download owns the metadata tables — a delta on
    // top of it would race the same rows.
    if (session.service.initialSyncRunning) return;

    _syncing.add(true);
    try {
      await MetadataSyncService(session.service.db, api).syncMetadataDelta();
    } finally {
      _syncing.add(false);
    }
  }

  /// Best-effort fix-up for rows queued while the device never opened
  /// the dataset's form (so DataEntryRepositoryImpl's own resolution
  /// never ran): if this instance's metadata still carries duplicate
  /// 'default' COCs, resolve the canonical one and rewrite any pending
  /// rows off the duplicates before they get pushed. The confirmed
  /// [canonicalDefaultComboUid] wins if it's synced locally (even over
  /// a stale cached verdict); only when it's missing does this fall
  /// back to the cache, then a fresh fetch. A failure here must not
  /// block the push — the rows just retry remapped next time.
  Future<void> _repairDuplicateDefaultCombos(AppDatabase db, ApiClient api) async {
    try {
      if (!await hasDuplicateDefaultCombos(db)) return;
      final known = await (db.select(db.categoryOptionCombosTable)
            ..where((t) => t.uid.equals(canonicalDefaultComboUid)))
          .getSingleOrNull();
      final canonical = known?.uid ??
          await db.getSyncInfo(defaultAttributeOptionComboSyncInfoKey) ??
          await fetchCanonicalDefaultCombo(db, api);
      if (canonical == null) return;
      await db.setSyncInfo(defaultAttributeOptionComboSyncInfoKey, canonical);
      await remapDuplicateDefaultCombos(db, canonical);
    } catch (e) {
      log.w('[autoSync] duplicate-default COC repair failed: $e');
    }
  }

  /// One blind CREATE_AND_UPDATE import for every pending value. No
  /// pull here — per-form conflict resolution happens when a form is
  /// opened (DataValueSync.syncForm); auto-sync's job is only to get
  /// queued offline work off the device.
  Future<int> _pushDataValues(AppDatabase db) async {
    final store = DataValueStore(db);
    final pending = await store.pendingValues();
    if (pending.isEmpty) return 0;

    final result = await pushDataValueBatch(
      api: AppSession.instance.api!,
      store: store,
      values: pending,
      logTag: 'autoSync',
    );
    return result.accepted;
  }
}

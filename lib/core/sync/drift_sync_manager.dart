import 'dart:async';

import '../auth/app_session.dart';
import '../data/completeness.dart';
import '../data/data_value_push.dart';
import '../data/data_value_store.dart';
import '../database/app_database.dart';
import '../metadata/metadata_sync_service.dart';
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
      final pushed = await _pushDataValues(db);
      final completions = await CompletenessSync(db, api).pushPending();
      if (pushed > 0 || completions > 0) {
        log.i('[autoSync] pushed $pushed values, $completions completions');
      }
    } finally {
      _running = false;
      _syncing.add(false);
    }
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

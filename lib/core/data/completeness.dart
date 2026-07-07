import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';

/// Complete / incomplete a dataset for a form instance. Same offline
/// pattern as data values (sync-stated, push-first), simpler (no
/// per-cell conflict — a registration is one boolean fact).
class CompletenessStore {
  CompletenessStore(this._db);

  final AppDatabase _db;

  /// Mark a form complete or incomplete locally, pending push.
  Future<void> setComplete({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required bool completed,
    String? storedBy,
  }) async {
    await _db.into(_db.completeDataSetRegistrationsTable).insertOnConflictUpdate(
          CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: dataSetUid,
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            completed: completed,
            storedBy: Value(storedBy),
            date: DateTime.now(),
            syncState: SyncState.pending,
            lastModified: DateTime.now(),
          ),
        );
  }

  Future<CompleteDataSetRegistration?> statusOf({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
  }) {
    return (_db.select(_db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(dataSetUid) &
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid)))
        .getSingleOrNull();
  }

  Future<List<CompleteDataSetRegistration>> pending() =>
      (_db.select(_db.completeDataSetRegistrationsTable)
            ..where((t) => t.syncState.equals(SyncState.pending.index)))
          .get();
}

/// Push/pull completeness registrations. Holds the ApiClient.
class CompletenessSync {
  CompletenessSync(this._db, this._api) : _store = CompletenessStore(_db);

  final AppDatabase _db;
  final ApiClient _api;
  final CompletenessStore _store;

  /// Push all pending registrations. completeDataSetRegistrations takes
  /// a list; completed=true POSTs, completed=false DELETEs.
  Future<int> pushPending() async {
    final pending = await _store.pending();
    if (pending.isEmpty) return 0;

    var ok = 0;
    for (final r in pending) {
      try {
        if (r.completed) {
          await _api.post('/api/completeDataSetRegistrations', data: {
            'completeDataSetRegistrations': [
              {
                'dataSet': r.dataSetUid,
                'period': r.period,
                'organisationUnit': r.orgUnitUid,
                'attributeOptionCombo': r.attributeOptionComboUid,
              }
            ]
          });
        } else {
          await _api.delete('/api/completeDataSetRegistrations',
              queryParameters: {
                'ds': r.dataSetUid,
                'pe': r.period,
                'ou': r.orgUnitUid,
              });
        }
        await _markSynced(r);
        ok++;
      } on DioException catch (e) {
        log.e('[completeness] push error for ${r.dataSetUid}/${r.period}: '
            '${e.message}');
        // leave pending, retry later
      }
    }
    log.i('[completeness] pushed $ok/${pending.length}');
    return ok;
  }

  Future<void> _markSynced(CompleteDataSetRegistration r) {
    return (_db.update(_db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(r.dataSetUid) &
              t.period.equals(r.period) &
              t.orgUnitUid.equals(r.orgUnitUid) &
              t.attributeOptionComboUid.equals(r.attributeOptionComboUid)))
        .write(const CompleteDataSetRegistrationsTableCompanion(
      syncState: Value(SyncState.synced),
    ));
  }
}

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'period_access.dart';

/// Complete / incomplete a dataset for a form instance. Same offline
/// pattern as data values (sync-stated, push-first), simpler (no
/// per-cell conflict — a registration is one boolean fact).
class CompletenessStore {
  CompletenessStore(this._db) : _clock = PeriodAccess(_db);

  final AppDatabase _db;
  final PeriodAccess _clock;

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
            // effectiveNow (monotonic high-water clock), NOT
            // DateTime.now() — same rule as DataValueStore, so a
            // backdated device can't fake completion timestamps.
            date: await _clock.effectiveNow(),
            syncState: SyncState.pending,
            lastModified: await _clock.effectiveNow(),
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
                // TODO(backend): datasets with non-default attribute
                // combos need cc (categoryCombo) + cp (option uids)
                // here or the wrong registration gets un-completed.
                // The app currently only writes the default combo.
              });
        }
        await _markSynced(r);
        ok++;
      } on DioException catch (e) {
        // A 409 is a server VERDICT (conflicts in the body), not a
        // transport failure — retrying the same registration forever
        // can't succeed, so settle it as an error the UI can surface.
        final data = e.response?.data;
        if (e.response?.statusCode == 409 && data is Map<String, dynamic>) {
          final summary =
              (data['response'] ?? data) as Map<String, dynamic>;
          final conflicts = (summary['conflicts'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          final why = conflicts.isNotEmpty
              ? conflicts.map((c) => c['value']).join('; ')
              : (data['message'] ?? 'Rejected by server').toString();
          log.w('[completeness] ${r.dataSetUid}/${r.period} rejected: $why');
          await _markError(r, why);
        } else {
          log.e('[completeness] push error for ${r.dataSetUid}/${r.period}: '
              '${e.message}');
          // leave pending, retry later
        }
      }
    }
    log.i('[completeness] pushed $ok/${pending.length}');
    return ok;
  }

  Future<void> _markSynced(CompleteDataSetRegistration r) =>
      _writeState(r, SyncState.synced);

  Future<void> _markError(CompleteDataSetRegistration r, String error) =>
      _writeState(r, SyncState.error, error);

  Future<void> _writeState(CompleteDataSetRegistration r, SyncState state,
      [String? error]) {
    return (_db.update(_db.completeDataSetRegistrationsTable)
          ..where((t) =>
              t.dataSetUid.equals(r.dataSetUid) &
              t.period.equals(r.period) &
              t.orgUnitUid.equals(r.orgUnitUid) &
              t.attributeOptionComboUid.equals(r.attributeOptionComboUid)))
        .write(CompleteDataSetRegistrationsTableCompanion(
      syncState: Value(state),
      syncError: Value(error),
    ));
  }
}

import '../utils/http_date.dart';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'data_value_push.dart';
import 'data_value_store.dart';
import 'period_access.dart';

/// Pull-then-compare-then-push for one form (dataset x period x
/// orgUnit). Holds the ApiClient — the only place data values touch the
/// network.
///
/// V2 CONFLICT RESOLUTION (per cell, during pull):
///   server slot empty            -> local pending stays, pushed later
///   values EQUAL                 -> mark synced, no push (saves a write)
///   values differ, clock TRUSTED -> NEWEST wins (server lastUpdated vs
///                                   local lastModified, monotonic HWM)
///   values differ, TAMPERED      -> server wins (stamps are suspect)
///   server timestamp missing     -> server wins (can't compare fairly)
///
/// Clock anchoring stays gated: the Date header is captured on every
/// contact but only APPLIED once nothing local is pending.
class DataValueSync {
  DataValueSync(this._db, this._api)
      : _store = DataValueStore(_db),
        _clock = PeriodAccess(_db);

  /// Local must be newer than server by MORE than this to win — a
  /// conservative bias toward the server for near-ties, absorbing
  /// residual clock skew between anchored local stamps and the server.
  static const _newestWinsTolerance = Duration(minutes: 2);

  final AppDatabase _db;
  final ApiClient _api;
  final DataValueStore _store;
  final PeriodAccess _clock;

  DateTime? _serverDate;

  /// Full form sync: pull + resolve, then push what remained pending.
  Future<DataValueSyncResult> syncForm({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required List<String> dataElementUids,
    required String attributeOptionComboUid,
  }) async {
    // 1. PULL + RESOLVE. If it fails we do NOT push (no read -> no push).
    final pull = await _pullAndResolve(
      dataSetUid: dataSetUid,
      period: period,
      orgUnitUid: orgUnitUid,
    );
    if (pull == null) {
      log.w('[dataValues] pull failed — push skipped, values stay pending');
      return const DataValueSyncResult(pulled: false);
    }

    // 2. PUSH everything still pending for this form: empty-slot values
    //    plus conflicts the LOCAL side won.
    final all = await _store.valuesForForm(
      period: period,
      orgUnitUid: orgUnitUid,
      attributeOptionComboUid: attributeOptionComboUid,
      dataElementUids: dataElementUids,
    );
    final toPush =
        all.where((v) => v.syncState == SyncState.pending).toList();

    var pushed = 0;
    var failed = 0;
    if (toPush.isNotEmpty) {
      (pushed, failed) = await _push(toPush);
    }
    await _maybeAnchor();
    return DataValueSyncResult(
      pulled: true,
      pushed: pushed,
      failed: failed,
      equalSkipped: pull.equalSkipped,
      serverWon: pull.serverWon,
      localWon: pull.localWon,
    );
  }

  /// PULL server values and resolve each against local state per the V2
  /// rules. Returns null on network failure.
  Future<_PullOutcome?> _pullAndResolve({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
  }) async {
    final List<Map<String, dynamic>> values;
    try {
      final Response res =
          await _api.get('/api/dataValueSets.json', queryParameters: {
        'dataSet': dataSetUid,
        'period': period,
        'orgUnit': orgUnitUid,
      });
      _captureServerDate(res);
      final data = res.data as Map<String, dynamic>;
      values = (data['dataValues'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      log.e('[dataValues] pull error: ${e.message}');
      return null;
    }

    final tampered = await _clock.isClockTampered();
    final stamp = await _clock.effectiveNow();
    var equalSkipped = 0, serverWon = 0, localWon = 0;

    for (final v in values) {
      final serverValue = v['value']?.toString();
      final local = await _store.findCell(
        dataElementUid: v['dataElement'] as String,
        period: v['period'] as String,
        orgUnitUid: v['orgUnit'] as String,
        categoryOptionComboUid: v['categoryOptionCombo'] as String,
        attributeOptionComboUid: v['attributeOptionCombo'] as String,
      );

      // No local edit in flight -> server state simply lands. ERROR
      // rows do NOT count as settled: they hold rejected local work
      // the user must still see and fix, so they go through the same
      // resolution rules as pending (but are never blind re-pushed —
      // editing the cell is what re-queues them). DRAFT rows settle
      // only when EQUAL to the server; on any conflict the draft
      // survives (see below), and phase 2 never pushes drafts.
      if (local == null || local.syncState == SyncState.synced) {
        await _applyServer(v, stamp);
        continue;
      }

      // EQUAL: nothing to transmit — flip pending -> synced, no push.
      if (local.value == serverValue) {
        await _store.markSynced(local);
        equalSkipped++;
        continue;
      }

      // CONFLICT with a DRAFT: the draft always survives. It is
      // unsubmitted work typed on this device — silently replacing it
      // with the server value would destroy input the user never had
      // a chance to send. It leaves the device only when the user
      // completes the data set (promoteDrafts -> pending -> push).
      if (local.syncState == SyncState.draft) {
        localWon++;
        continue;
      }

      // CONFLICT.
      if (tampered) {
        await _applyServer(v, stamp); // suspect stamps: server wins
        serverWon++;
        continue;
      }
      final serverUpdated =
          DateTime.tryParse(v['lastUpdated'] as String? ?? '');
      if (serverUpdated == null) {
        await _applyServer(v, stamp); // can't compare fairly: server wins
        serverWon++;
        continue;
      }
      final localIsNewer = local.lastModified
          .isAfter(serverUpdated.add(_newestWinsTolerance));
      if (localIsNewer) {
        localWon++; // stays pending -> pushed in phase 2
      } else {
        await _applyServer(v, stamp);
        serverWon++;
      }
    }

    if (serverWon + localWon > 0) {
      log.i('[dataValues] conflicts: $serverWon server-won, '
          '$localWon local-won${tampered ? ' (clock tampered)' : ''}');
    }
    log.i('[dataValues] pulled ${values.length} '
        '($equalSkipped equal-skipped) for $dataSetUid/$period/$orgUnitUid');
    return _PullOutcome(equalSkipped, serverWon, localWon);
  }

  Future<void> _applyServer(Map<String, dynamic> v, DateTime stamp) {
    return _store.applyServerValue(DataValuesTableCompanion.insert(
      dataElementUid: v['dataElement'] as String,
      period: v['period'] as String,
      orgUnitUid: v['orgUnit'] as String,
      categoryOptionComboUid: v['categoryOptionCombo'] as String,
      attributeOptionComboUid: v['attributeOptionCombo'] as String,
      value: Value(v['value']?.toString()),
      comment: Value(v['comment'] as String?),
      storedBy: Value(v['storedBy'] as String?),
      syncState: SyncState.synced,
      lastModified: stamp,
    ));
  }

  /// PUSH pending values. importStrategy CREATE_AND_UPDATE + atomicMode
  /// NONE => partial success. Returns (accepted, rejected).
  Future<(int, int)> _push(List<DataValue> values) async {
    final result = await pushDataValueBatch(
      api: _api,
      store: _store,
      values: values,
      onResponse: _captureServerDate,
    );
    if (result.transportFailed) {
      return (0, 0); // everything stays pending; retry later
    }
    log.i('[dataValues] pushed ok: ${result.accepted}');
    return (result.accepted, result.rejected);
  }

  void _captureServerDate(Response res) {
    final raw = res.headers.value('date');
    if (raw == null) return;
    try {
      _serverDate = parseHttpDate(raw);
    } catch (_) {}
  }

  /// ANCHOR GATE: recalibration only once nothing local is pending —
  /// otherwise deferred to a later, fully-settled contact.
  Future<void> _maybeAnchor() async {
    final serverDate = _serverDate;
    if (serverDate == null) return;
    if (await hasUnsyncedLocalData(_db)) {
      log.i('[clock] anchor deferred — pending local data must sync first');
      return;
    }
    await _clock.anchorToServer(serverDate);
  }
}

class _PullOutcome {
  const _PullOutcome(this.equalSkipped, this.serverWon, this.localWon);
  final int equalSkipped;
  final int serverWon;
  final int localWon;
}

class DataValueSyncResult {
  const DataValueSyncResult({
    required this.pulled,
    this.pushed = 0,
    this.failed = 0,
    this.equalSkipped = 0,
    this.serverWon = 0,
    this.localWon = 0,
  });

  final bool pulled;
  final int pushed;
  final int failed;

  /// Cells identical on both sides: flipped to synced without a push.
  final int equalSkipped;

  /// Conflicts resolved in the server's favour.
  final int serverWon;

  /// Conflicts kept local (newer) and pushed.
  final int localWon;

  @override
  String toString() => 'pulled=$pulled pushed=$pushed failed=$failed '
      'equal=$equalSkipped serverWon=$serverWon localWon=$localWon';
}

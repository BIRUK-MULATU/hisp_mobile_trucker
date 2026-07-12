import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/app_logger.dart';
import 'period_access.dart';

/// Locally-owned data values. NOT a MetadataResource subclass — data
/// values have a composite key (not a uid), carry sync state, and are
/// pushed rather than fetched-and-mirrored.
///
/// Identity = (dataElement, period, orgUnit, categoryOptionCombo,
/// attributeOptionCombo).
///
/// Clock integration: every lastModified stamp comes from
/// PeriodAccess.effectiveNow() — the monotonic high-water clock — so a
/// backdated device can never produce a stamp earlier than anything
/// already observed. Period-level gating (expired / blockedTampered)
/// is enforced by the picker/UI via PeriodAccess; the store logs a
/// warning if a write arrives while the tamper flag is set, but stays
/// mechanical.
class DataValueStore {
  DataValueStore(this._db) : _clock = PeriodAccess(_db);

  final AppDatabase _db;
  final PeriodAccess _clock;

  // ── WRITE (local entry) ──────────────────────────────────────────────

  /// Save a locally-entered value. Single-row upsert (atomic).
  /// Re-editing the same cell overwrites via the composite key.
  /// [draft] keeps the value device-only (no sync path touches it)
  /// until [promoteDrafts] flips it to pending on form completion.
  Future<void> setValue({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    required String categoryOptionComboUid,
    required String attributeOptionComboUid,
    required String? value,
    String? comment,
    String? storedBy,
    bool draft = false,
  }) async {
    if (await _clock.isClockTampered()) {
      log.w('[dataValues] write while clock tamper flag is set '
          '($dataElementUid/$period) — stamp uses high-water mark');
    }
    await _db.into(_db.dataValuesTable).insertOnConflictUpdate(
          DataValuesTableCompanion.insert(
            dataElementUid: dataElementUid,
            period: period,
            orgUnitUid: orgUnitUid,
            categoryOptionComboUid: categoryOptionComboUid,
            attributeOptionComboUid: attributeOptionComboUid,
            value: Value(value),
            comment: Value(comment),
            storedBy: Value(storedBy),
            syncState: draft ? SyncState.draft : SyncState.pending,
            lastModified: await _clock.effectiveNow(),
          ),
        );
  }

  /// Completing a form is the moment drafts become sendable: flip the
  /// form's draft rows (scoped to the dataset's elements) to pending
  /// so the normal push paths pick them up. Returns the row count.
  Future<int> promoteDrafts({
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required List<String> dataElementUids,
  }) {
    return (_db.update(_db.dataValuesTable)
          ..where((t) =>
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid) &
              t.dataElementUid.isIn(dataElementUids) &
              t.syncState.equals(SyncState.draft.index)))
        .write(const DataValuesTableCompanion(
      syncState: Value(SyncState.pending),
    ));
  }

  // ── READ ─────────────────────────────────────────────────────────────

  /// All values for one form instance — the entry form fills its cells
  /// from this.
  Future<List<DataValue>> valuesForForm({
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required List<String> dataElementUids,
  }) {
    return (_db.select(_db.dataValuesTable)
          ..where((t) =>
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid) &
              t.dataElementUid.isIn(dataElementUids)))
        .get();
  }

  Future<List<DataValue>> pendingValues() => (_db.select(_db.dataValuesTable)
        ..where((t) => t.syncState.equals(SyncState.pending.index)))
      .get();

  Future<int> pendingCount() async {
    final c = _db.dataValuesTable.dataElementUid.count();
    final q = _db.selectOnly(_db.dataValuesTable)
      ..addColumns([c])
      ..where(_db.dataValuesTable.syncState.equals(SyncState.pending.index));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Values still held as device-only drafts — the sync UI mentions
  /// them so "everything is synced" doesn't read as "nothing left on
  /// this phone".
  Future<int> draftCount() async {
    final c = _db.dataValuesTable.dataElementUid.count();
    final q = _db.selectOnly(_db.dataValuesTable)
      ..addColumns([c])
      ..where(_db.dataValuesTable.syncState.equals(SyncState.draft.index));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Datasets with un-uploaded work at one org unit — any pending or
  /// error data value (mapped to datasets through dataSetElements) or
  /// completion registration. Feeds the capture list's synced/unsync
  /// chips. A data element shared between datasets flags every dataset
  /// that contains it: the value IS un-uploaded in all of them.
  Future<Set<String>> unsyncedDataSetsAt(String orgUnitUid) async {
    final dv = _db.dataValuesTable;
    final unsyncedElements = await (_db.selectOnly(dv, distinct: true)
          ..addColumns([dv.dataElementUid])
          ..where(dv.orgUnitUid.equals(orgUnitUid) &
              dv.syncState.equals(SyncState.synced.index).not()))
        .get();
    final elementUids = [
      for (final r in unsyncedElements) r.read(dv.dataElementUid)!,
    ];

    final result = <String>{};
    if (elementUids.isNotEmpty) {
      final dse = _db.dataSetElementsTable;
      final rows = await (_db.selectOnly(dse, distinct: true)
            ..addColumns([dse.dataSetUid])
            ..where(dse.dataElementUid.isIn(elementUids)))
          .get();
      result.addAll([for (final r in rows) r.read(dse.dataSetUid)!]);
    }

    final cdr = _db.completeDataSetRegistrationsTable;
    final compRows = await (_db.selectOnly(cdr, distinct: true)
          ..addColumns([cdr.dataSetUid])
          ..where(cdr.orgUnitUid.equals(orgUnitUid) &
              cdr.syncState.equals(SyncState.synced.index).not()))
        .get();
    result.addAll([for (final r in compRows) r.read(cdr.dataSetUid)!]);
    return result;
  }

  /// Org units that have captured work (data values or completion
  /// registrations) matching the capture filters: any of [states]
  /// (empty = any state) and, when given, last modified inside
  /// [from] (inclusive) .. [to] (exclusive). Feeds the capture
  /// org-unit filter — the result is inherently within the user's
  /// assigned scope because local work only exists where they
  /// captured through that tree.
  Future<Set<String>> orgUnitsWithWork({
    Set<SyncState> states = const {},
    DateTime? from,
    DateTime? to,
  }) async {
    final stateIndexes = [for (final s in states) s.index];
    final result = <String>{};

    final dv = _db.dataValuesTable;
    final dvQuery = _db.selectOnly(dv, distinct: true)
      ..addColumns([dv.orgUnitUid]);
    if (stateIndexes.isNotEmpty) {
      dvQuery.where(dv.syncState.isIn(stateIndexes));
    }
    if (from != null) dvQuery.where(dv.lastModified.isBiggerOrEqualValue(from));
    if (to != null) dvQuery.where(dv.lastModified.isSmallerThanValue(to));
    result.addAll([
      for (final r in await dvQuery.get()) r.read(dv.orgUnitUid)!,
    ]);

    final cdr = _db.completeDataSetRegistrationsTable;
    final cdrQuery = _db.selectOnly(cdr, distinct: true)
      ..addColumns([cdr.orgUnitUid]);
    if (stateIndexes.isNotEmpty) {
      cdrQuery.where(cdr.syncState.isIn(stateIndexes));
    }
    if (from != null) {
      cdrQuery.where(cdr.lastModified.isBiggerOrEqualValue(from));
    }
    if (to != null) cdrQuery.where(cdr.lastModified.isSmallerThanValue(to));
    result.addAll([
      for (final r in await cdrQuery.get()) r.read(cdr.orgUnitUid)!,
    ]);

    return result;
  }

  Future<DataValue?> findCell({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    required String categoryOptionComboUid,
    required String attributeOptionComboUid,
  }) {
    return (_db.select(_db.dataValuesTable)
          ..where((t) =>
              t.dataElementUid.equals(dataElementUid) &
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.categoryOptionComboUid.equals(categoryOptionComboUid) &
              t.attributeOptionComboUid.equals(attributeOptionComboUid)))
        .getSingleOrNull();
  }

  // ── SYNC-STATE TRANSITIONS ───────────────────────────────────────────

  Future<void> markSynced(DataValue v) => _writeState(v, SyncState.synced);

  Future<void> markError(DataValue v, String error) =>
      _writeState(v, SyncState.error, error);

  Future<void> _writeState(DataValue v, SyncState state, [String? err]) {
    return (_db.update(_db.dataValuesTable)
          ..where((t) =>
              t.dataElementUid.equals(v.dataElementUid) &
              t.period.equals(v.period) &
              t.orgUnitUid.equals(v.orgUnitUid) &
              t.categoryOptionComboUid.equals(v.categoryOptionComboUid) &
              t.attributeOptionComboUid.equals(v.attributeOptionComboUid)))
        .write(DataValuesTableCompanion(
      syncState: Value(state),
      syncError: Value(err),
    ));
  }

  /// Apply a value pulled from the server. CONFLICT RULE (v1): server
  /// wins — this upserts as synced, overwriting any local value at the
  /// same key. Local pending values survive only where the server
  /// returned nothing (the caller simply never calls this for those
  /// cells).
  Future<void> applyServerValue(DataValuesTableCompanion serverValue) async {
    await _db.into(_db.dataValuesTable).insertOnConflictUpdate(
          serverValue.copyWith(syncState: const Value(SyncState.synced)),
        );
  }
}

/// The anchor gate: true when ANY local data (values or completions)
/// is still pending its first successful sync. While true, the clock
/// must NOT be re-anchored / tamper-cleared — reconcile first, then
/// recalibrate. Error-state rows do NOT block (already surfaced).
Future<bool> hasUnsyncedLocalData(AppDatabase db) async {
  // Drafts count too: their stamps feed the same newest-wins
  // comparison once promoted, so the clock must not re-anchor
  // underneath them.
  final v = await (db.selectOnly(db.dataValuesTable)
        ..addColumns([db.dataValuesTable.dataElementUid.count()])
        ..where(db.dataValuesTable.syncState
            .isIn([SyncState.pending.index, SyncState.draft.index])))
      .getSingle();
  if ((v.read(db.dataValuesTable.dataElementUid.count()) ?? 0) > 0) {
    return true;
  }
  final c = await (db.selectOnly(db.completeDataSetRegistrationsTable)
        ..addColumns([db.completeDataSetRegistrationsTable.dataSetUid.count()])
        ..where(db.completeDataSetRegistrationsTable.syncState
            .equals(SyncState.pending.index)))
      .getSingle();
  return (c.read(db.completeDataSetRegistrationsTable.dataSetUid.count()) ??
          0) >
      0;
}

/// Rows that exist ONLY on this device: draft/pending/error data values
/// plus pending/error completion registrations. Unlike
/// [hasUnsyncedLocalData] (a clock-anchor gate, which ignores error
/// rows on purpose), this counts EVERYTHING a database wipe would
/// destroy — error rows are still the user's field data. Wipe-style
/// flows must confirm against this count before deleting.
Future<int> countUnsyncedWork(AppDatabase db) async {
  final notSynced = [
    SyncState.pending.index,
    SyncState.draft.index,
    SyncState.error.index,
  ];
  final dvCount = db.dataValuesTable.dataElementUid.count();
  final v = await (db.selectOnly(db.dataValuesTable)
        ..addColumns([dvCount])
        ..where(db.dataValuesTable.syncState.isIn(notSynced)))
      .getSingle();
  final cdrCount = db.completeDataSetRegistrationsTable.dataSetUid.count();
  final c = await (db.selectOnly(db.completeDataSetRegistrationsTable)
        ..addColumns([cdrCount])
        ..where(db.completeDataSetRegistrationsTable.syncState.isIn(notSynced)))
      .getSingle();
  return (v.read(dvCount) ?? 0) + (c.read(cdrCount) ?? 0);
}

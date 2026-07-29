import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Append-only trail of local edits to data values and completion
/// registrations — old value, new value, who, when. Written by
/// [DataValueStore.setValue] and [CompletenessStore.setComplete]
/// themselves so every write path is covered without call sites having
/// to remember to log anything.
class AuditLogStore {
  AuditLogStore(this._db);

  final AppDatabase _db;

  /// No-op when [previousValue] == [newValue] — an edit that changes
  /// nothing isn't an event worth keeping.
  Future<void> recordDataValue({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    required String categoryOptionComboUid,
    required String attributeOptionComboUid,
    required String? previousValue,
    required String? newValue,
    required String? modifiedBy,
    required DateTime modifiedAt,
  }) async {
    if (previousValue == newValue) return;
    await _db.into(_db.auditLogTable).insert(
          AuditLogTableCompanion.insert(
            entityType: AuditEntityType.dataValue,
            dataElementUid: Value(dataElementUid),
            categoryOptionComboUid: Value(categoryOptionComboUid),
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            previousValue: Value(previousValue),
            newValue: Value(newValue),
            modifiedBy: Value(modifiedBy),
            modifiedAt: modifiedAt,
          ),
        );
  }

  /// No-op when [previousCompleted] already matches [completed].
  Future<void> recordCompleteness({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required bool? previousCompleted,
    required bool completed,
    required String? modifiedBy,
    required DateTime modifiedAt,
  }) async {
    if (previousCompleted == completed) return;
    await _db.into(_db.auditLogTable).insert(
          AuditLogTableCompanion.insert(
            entityType: AuditEntityType.completeness,
            dataSetUid: Value(dataSetUid),
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            previousValue: Value(previousCompleted?.toString()),
            newValue: Value(completed.toString()),
            modifiedBy: Value(modifiedBy),
            modifiedAt: modifiedAt,
          ),
        );
  }

  /// Local history for one cell, newest first — the offline fallback
  /// behind the per-combo "history" sheet. Deliberately NOT filtered by
  /// attributeOptionCombo (the caller doesn't always have it to hand,
  /// and in practice a form uses a single default one), so this is a
  /// looser match than [forDataValueCell]; fine for a fallback view.
  Future<List<AuditEntry>> forCell({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    required String categoryOptionComboUid,
  }) {
    return (_db.select(_db.auditLogTable)
          ..where((t) =>
              t.entityType.equals(AuditEntityType.dataValue.index) &
              t.dataElementUid.equals(dataElementUid) &
              t.period.equals(period) &
              t.orgUnitUid.equals(orgUnitUid) &
              t.categoryOptionComboUid.equals(categoryOptionComboUid))
          ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
        .get();
  }

}

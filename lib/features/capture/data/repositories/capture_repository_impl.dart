import 'package:drift/drift.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/metadata/organisation_unit.dart';
import '../../../../core/metadata/section.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../../domain/entities/report_instance_entity.dart';
import '../../domain/repositories/capture_repository.dart';

/// Capture navigation entirely on the local database — the synced
/// metadata IS the user's world, so browsing org units, datasets and
/// sections needs no network at all.
class CaptureRepositoryImpl implements CaptureRepository {
  final SessionService _session;

  CaptureRepositoryImpl({SessionService? session})
      : _session = session ?? AppSession.instance.service;

  AppDatabase get _db => _session.db;

  @override
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId) async {
    final children = await OrgUnitResource(_db).getChildren(parentId);
    if (children.isEmpty) return const [];

    // One grouped query for the expand arrows: how many children does
    // each child itself have.
    final t = _db.orgUnitsTable;
    final countExp = t.uid.count();
    final grouped = await (_db.selectOnly(t)
          ..addColumns([t.parentUid, countExp])
          ..where(t.parentUid.isIn([for (final c in children) c.uid]))
          ..groupBy([t.parentUid]))
        .get();
    final childCounts = {
      for (final row in grouped) row.read(t.parentUid)!: row.read(countExp)!,
    };

    return [
      for (final c in children)
        OrgUnitTreeNode(
          id: c.uid,
          name: c.displayName,
          parentId: parentId,
          // level is not stored — derive from the path (/a/b/c = 3).
          level: '/'.allMatches(c.path).length,
          path: c.path,
          childCount: childCounts[c.uid] ?? 0,
        ),
    ];
  }

  @override
  Future<List<DataSetEntity>> getDataSetsForOrgUnit(String orgUnitId) async {
    final rows = await DataSetResource(_db).getByOrgUnit(orgUnitId);
    if (rows.isEmpty) {
      // Distinguish "nothing assigned" from "never synced".
      final anyMeta = await (_db.select(_db.dataSetsTable)..limit(1)).get();
      if (anyMeta.isEmpty) {
        if (_session.initialSyncRunning) {
          throw const CacheException(
              message: 'Your data is still downloading — '
                  'try again in a moment.');
        }
        throw const CacheException(
            message: 'No metadata on this device yet — '
                'log in online once to sync.');
      }
    }
    // Chip truth comes from the local write queue: a dataset is
    // "unsync" while any of its values/completions here await upload.
    final unsynced = await DataValueStore(_db).unsyncedDataSetsAt(orgUnitId);
    return [
      for (final ds in rows)
        DataSetEntity(
          id: ds.uid,
          name: ds.displayName,
          periodType: ds.periodType,
          syncStatus: unsynced.contains(ds.uid)
              ? SyncStatus.unsynced
              : SyncStatus.synced,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<OrgUnitTreeNode>> getOrgUnitsByIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final t = _db.orgUnitsTable;
    final rows = await (_db.select(t)..where((t) => t.uid.isIn(ids))).get();
    return [
      for (final ou in rows)
        OrgUnitTreeNode(
          id: ou.uid,
          name: ou.displayName,
          parentId: ou.parentUid,
          level: '/'.allMatches(ou.path).length,
          path: ou.path,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<ReportInstanceEntity>> getUserReports() async {
    // (dataset, period, orgUnit) -> the report's local truth.
    final byKey = <(String, String, String), _ReportFacts>{};
    _ReportFacts factsFor((String, String, String) key) =>
        byKey[key] ??= _ReportFacts();

    final cdr = _db.completeDataSetRegistrationsTable;
    final completions = await (_db.select(cdr)
          ..where((t) => t.completed.equals(true)))
        .get();
    for (final r in completions) {
      factsFor((r.dataSetUid, r.period, r.orgUnitUid))
        ..completed = true
        ..completionSynced = r.syncState == SyncState.synced
        ..completionError =
            r.syncState == SyncState.error ? r.syncError : null
        ..touch(r.lastModified);
    }

    // Every value not yet on the server — drafts, queued, rejected —
    // marks its report as having local work.
    final dv = _db.dataValuesTable;
    final unsyncedValues = await (_db.select(dv)
          ..where((t) => t.syncState.equals(SyncState.synced.index).not()))
        .get();
    if (unsyncedValues.isNotEmpty) {
      // Values carry no dataset — map through dataSetElements. A
      // shared element flags every dataset containing it, same rule
      // as unsyncedDataSetsAt: the work IS unfinished in all of them.
      final dse = _db.dataSetElementsTable;
      final links = await (_db.select(dse)
            ..where((t) => t.dataElementUid
                .isIn({for (final d in unsyncedValues) d.dataElementUid})))
          .get();
      final dataSetsByElement = <String, Set<String>>{};
      for (final l in links) {
        (dataSetsByElement[l.dataElementUid] ??= {}).add(l.dataSetUid);
      }
      for (final d in unsyncedValues) {
        for (final ds
            in dataSetsByElement[d.dataElementUid] ?? const <String>{}) {
          factsFor((ds, d.period, d.orgUnitUid))
            ..hasUnsyncedValues = true
            ..hasDrafts |= d.syncState == SyncState.draft
            ..touch(d.lastModified);
        }
      }
    }
    if (byKey.isEmpty) return const [];

    // Resolve display names once for all keys.
    final dataSetRows = await (_db.select(_db.dataSetsTable)
          ..where((t) => t.uid.isIn({for (final k in byKey.keys) k.$1})))
        .get();
    final dataSetByUid = {for (final r in dataSetRows) r.uid: r};
    final orgUnitRows = await (_db.select(_db.orgUnitsTable)
          ..where((t) => t.uid.isIn({for (final k in byKey.keys) k.$3})))
        .get();
    final orgUnitNames = {
      for (final r in orgUnitRows) r.uid: r.displayName,
    };

    return [
      for (final MapEntry(key: k, value: v) in byKey.entries)
        // Dataset metadata gone (unassigned since): nothing to open.
        if (dataSetByUid[k.$1] != null)
          ReportInstanceEntity(
            dataSetId: k.$1,
            dataSetName: dataSetByUid[k.$1]!.displayName,
            periodType: dataSetByUid[k.$1]!.periodType,
            periodId: k.$2,
            periodLabel: EthiopianPeriodService.formatPeriodId(k.$2),
            orgUnitId: k.$3,
            orgUnitName: orgUnitNames[k.$3] ?? k.$3,
            status: v.status,
            synced: v.synced,
            lastModified: v.lastModified,
            syncError: v.completionError,
          ),
    ]..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  @override
  Future<List<DataSetSectionEntity>> getSections(String dataSetId) async {
    final rows = await SectionResource(_db).getByDataSet(dataSetId);
    return [
      for (final s in rows)
        DataSetSectionEntity(
          id: s.uid,
          name: s.displayName,
          sortOrder: s.sortOrder,
        ),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

/// Accumulated local facts of one report while [getUserReports]
/// scans completions and unsynced values.
class _ReportFacts {
  bool completed = false;
  bool completionSynced = true;
  String? completionError;
  bool hasUnsyncedValues = false;
  bool hasDrafts = false;
  DateTime lastModified = DateTime.fromMillisecondsSinceEpoch(0);

  void touch(DateTime t) {
    if (t.isAfter(lastModified)) lastModified = t;
  }

  /// Drafts reopen a report: even a completed one is being reworked.
  ReportStatus get status => completed && !hasDrafts
      ? ReportStatus.completed
      : ReportStatus.incomplete;

  bool get synced => !hasUnsyncedValues && (!completed || completionSynced);
}

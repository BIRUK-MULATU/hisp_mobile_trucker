import 'package:drift/drift.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/metadata/organisation_unit.dart';
import '../../../../core/metadata/section.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../../domain/entities/report_instance_entity.dart';
import '../../domain/repositories/capture_repository.dart';

/// Capture navigation is LOCAL-FIRST — the synced metadata (root +
/// direct children only, see OrgUnitResource) is what's available
/// offline. Beyond that depth, browsing and opening a dataset both
/// fall back to a LIVE query when online (never attempted offline —
/// there's genuinely nothing more to show without a connection). A
/// facility reached this way gets cached locally the moment its
/// dataset list is actually opened (not just browsed past), so it's
/// usable offline from then on without needing much device storage
/// for facilities nobody has actually visited.
class CaptureRepositoryImpl implements CaptureRepository {
  final SessionService _session;
  final ApiClient? _apiOverride;

  CaptureRepositoryImpl({SessionService? session, ApiClient? api})
      : _session = session ?? AppSession.instance.service,
        _apiOverride = api;

  AppDatabase get _db => _session.db;

  /// Null offline (or logged in locally-only) — every live call site
  /// checks this instead of throwing, since offline is an expected,
  /// silent "nothing more to show" here, not an error.
  ApiClient? get _api => _apiOverride ?? AppSession.instance.api;

  @override
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId) async {
    final children = await OrgUnitResource(_db).getChildren(parentId);
    if (children.isEmpty) {
      // Beyond the direct-children depth bound (or a true leaf) —
      // live is the only way to tell, and only possible online. A
      // non-null ApiClient means "logged in", NOT "currently
      // connected" — genuinely offline, the request throws
      // (connection error), which is expected here, not a real
      // failure: nothing more to show without a connection.
      final api = _api;
      if (api == null) return const [];
      try {
        return await _fetchChildrenLive(api, parentId);
      } catch (_) {
        return const [];
      }
    }

    // One grouped query for the expand arrows: how many children does
    // each child itself have — accurate LOCALLY, except for a capture
    // root's direct children specifically: anything past THEM is
    // deliberately never synced, so their local count is always 0
    // whether or not real children exist on the server. Correct that
    // one boundary with a live existence check (only possible/needed
    // online — offline, 0 is the right answer: there's nothing more
    // to show without a connection anyway).
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

    final api = _api;
    if (api != null) {
      final parent = await OrgUnitResource(_db).getById(parentId);
      if (parent?.isUserCaptureRoot ?? false) {
        for (final c in children) {
          if ((childCounts[c.uid] ?? 0) == 0) {
            try {
              childCounts[c.uid] = await _hasLiveChildren(api, c.uid) ? 1 : 0;
            } catch (_) {
              // Offline mid-loop (or any other failure) — leave this
              // child's count at its local (0) value; the arrow just
              // won't show until a later successful check.
            }
          }
        }
      }
    }

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

  /// Live children of [parentId], mapped the same shape as the local
  /// query — NOT persisted here (browsing alone shouldn't cache
  /// anything; see [getDataSetsForOrgUnit] for what actually does).
  Future<List<OrgUnitTreeNode>> _fetchChildrenLive(
      ApiClient api, String parentId) async {
    final res = await api.get('/api/organisationUnits.json', queryParameters: {
      'filter': 'parent.id:eq:$parentId',
      'fields': 'id,displayName,path,children[id]',
      'paging': 'false',
    });
    final items = ((res.data as Map<String, dynamic>)['organisationUnits']
                as List? ??
            const [])
        .cast<Map<String, dynamic>>();
    final nodes = [
      for (final ou in items)
        OrgUnitTreeNode(
          id: ou['id'] as String,
          name: (ou['displayName'] ?? '') as String,
          parentId: parentId,
          level: '/'.allMatches((ou['path'] as String? ?? '')).length,
          path: ou['path'] as String?,
          childCount: (ou['children'] as List? ?? const []).length,
        ),
    ];
    nodes.sort((a, b) => a.name.compareTo(b.name));
    return nodes;
  }

  /// Cheap existence check: does [uid] have at least one child on the
  /// server? Used only to decide whether a capture root's direct
  /// child gets an expand arrow (see [getOrgUnitChildren]) — a
  /// pageSize of 1 keeps this a minimal request, not a full fetch.
  Future<bool> _hasLiveChildren(ApiClient api, String uid) async {
    final res = await api.get('/api/organisationUnits.json', queryParameters: {
      'filter': 'parent.id:eq:$uid',
      'fields': 'id',
      'pageSize': '1',
    });
    final items =
        (res.data as Map<String, dynamic>)['organisationUnits'] as List?;
    return items != null && items.isNotEmpty;
  }

  @override
  Future<List<DataSetEntity>> getDataSetsForOrgUnit(String orgUnitId) async {
    var rows = await DataSetResource(_db).getByOrgUnit(orgUnitId);
    if (rows.isEmpty) {
      final api = _api;
      if (api != null) {
        try {
          rows = await _fetchAndCacheVisitedOrgUnit(api, orgUnitId);
        } catch (_) {
          // Offline (or the request otherwise failed) — fall through
          // to the "nothing assigned / never synced" handling below,
          // same as if there were no api at all.
        }
      }
    }
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
    final diseaseDataSets =
        await DataSetResource(_db).diseaseRegistrationDataSetUids();
    return [
      for (final ds in rows)
        DataSetEntity(
          id: ds.uid,
          name: ds.displayName,
          periodType: ds.periodType,
          syncStatus: unsynced.contains(ds.uid)
              ? SyncStatus.unsynced
              : SyncStatus.synced,
          isDiseaseRegistration: diseaseDataSets.contains(ds.uid),
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// The user has genuinely opened (not just browsed past) a facility
  /// beyond the synced depth bound — fetch its own record plus its
  /// dataset assignments live, and CACHE both locally, so this one
  /// facility (not the whole hierarchy) is usable offline from here
  /// on. Dataset metadata itself needs no fetching here: DataSetResource
  /// syncs every dataset's full definition regardless of org unit
  /// scope already, only the ASSIGNMENT (which datasets this facility
  /// has) and the facility's own row are missing locally.
  Future<List<DataSet>> _fetchAndCacheVisitedOrgUnit(
      ApiClient api, String orgUnitId) async {
    final res = await api.get('/api/organisationUnits/$orgUnitId.json',
        queryParameters: {
          'fields': 'id,name,displayName,parent[id,name],path,code,'
              'openingDate,closedDate,lastUpdated,dataSets[id]',
        });
    final json = res.data as Map<String, dynamic>;
    final dataSetUids = [
      for (final ds
          in (json['dataSets'] as List? ?? const []).cast<Map<String, dynamic>>())
        ds['id'] as String,
    ];

    await _db
        .into(_db.orgUnitsTable)
        .insertOnConflictUpdate(OrgUnitResource(_db).companionFromJson(json));
    if (dataSetUids.isNotEmpty) {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.dataSetOrgUnitsTable, [
          for (final dsUid in dataSetUids)
            DataSetOrgUnitsTableCompanion.insert(
                dataSetUid: dsUid, orgUnitUid: orgUnitId),
        ]);
      });
    }

    return DataSetResource(_db).getByIds(dataSetUids);
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
    // (dataset, period, orgUnit, attributeOptionCombo) -> the
    // report's local truth. The AOC is part of the key: a dataset
    // with a real category combo (e.g. Disease Registration's
    // Department × Outcome) can have several distinct reports for
    // the very same dataset/period/org unit.
    final byKey = <(String, String, String, String), _ReportFacts>{};
    _ReportFacts factsFor((String, String, String, String) key) =>
        byKey[key] ??= _ReportFacts();

    final cdr = _db.completeDataSetRegistrationsTable;
    final completions =
        await (_db.select(cdr)..where((t) => t.completed.equals(true))).get();
    for (final r in completions) {
      factsFor((r.dataSetUid, r.period, r.orgUnitUid, r.attributeOptionComboUid))
        ..completed = true
        ..completionSynced = r.syncState == SyncState.synced
        ..completionError = r.syncState == SyncState.error ? r.syncError : null
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
          factsFor((ds, d.period, d.orgUnitUid, d.attributeOptionComboUid))
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
    // Reports carry the same disease flag as the dataset list, so a
    // reopened Disease Registration report gets the same styling.
    final diseaseDataSets =
        await DataSetResource(_db).diseaseRegistrationDataSetUids();
    // AOC display names — null/'default' means nothing worth showing.
    final aocRows = await (_db.select(_db.categoryOptionCombosTable)
          ..where((t) => t.uid.isIn({for (final k in byKey.keys) k.$4})))
        .get();
    final aocNames = {for (final r in aocRows) r.uid: r.name};

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
            isDiseaseRegistration: diseaseDataSets.contains(k.$1),
            attributeOptionComboUid: k.$4,
            attributeOptionComboLabel: aocNames[k.$4] == null ||
                    aocNames[k.$4] == 'default'
                ? null
                : aocNames[k.$4],
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

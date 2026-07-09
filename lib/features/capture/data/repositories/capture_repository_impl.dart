import 'package:drift/drift.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/metadata/organisation_unit.dart';
import '../../../../core/metadata/section.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/entities/org_unit_tree_node.dart';
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

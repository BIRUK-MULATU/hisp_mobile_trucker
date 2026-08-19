import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('OrgUnit')
class OrgUnitsTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get parentUid => text().nullable()();
  TextColumn get parentName => text().nullable()();
  TextColumn get path => text()();
  TextColumn get code => text().nullable()();
  TextColumn get openingDate => text().nullable()();
  TextColumn get closedDate => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  /// True for the roots of the logged-in user's capture tree
  /// (set from /api/me by the sync service, not by this resource).
  BoolColumn get isUserCaptureRoot =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

class OrgUnitResource extends MetadataResource<OrgUnit> {
  OrgUnitResource(super.db);

  /// When set (by MetadataSyncService, from /api/me), the sync pulls
  /// ONLY the user's capture subtree(s) instead of the national tree —
  /// `path:like:<uid>` matches the root itself and every descendant.
  /// Empty = unfiltered (local-only use never syncs anyway). This is
  /// still deliberately unbounded by depth: DHIS2's filter API can't
  /// AND a second condition onto this without breaking the OR that
  /// combines multiple capture roots together (see [isValid] for the
  /// actual depth bound, applied after the fetch instead).
  List<String> captureRootUids = const [];

  /// Hierarchy level of each capture root, keyed by uid — lets
  /// [isValid] work out "is this org unit more than one level below
  /// its capture root" without a second network round-trip. Empty =
  /// no depth bound (today's full-subtree behavior).
  Map<String, int> captureRootLevels = const {};

  @override
  List<String> get filters =>
      [for (final uid in captureRootUids) 'path:like:$uid'];

  /// Keeps a fetched org unit only if it IS a capture root, or is
  /// exactly one level below one — a Woreda-assigned user's synced
  /// (and therefore navigable/enterable) org units stop at their
  /// direct children (e.g. PHCUs), never descending into the Health
  /// Centers/Posts beneath each of those. Deeper descendants are
  /// still fetched over the network (DHIS2's filter API has no way to
  /// bound depth server-side while OR-combining multiple roots — see
  /// [captureRootUids]) but are discarded here before anything is
  /// written locally, so they're simply unknown to the rest of the
  /// app: not in the org unit tree, not selectable, not enterable.
  @override
  bool isValid(Map<String, dynamic> json) =>
      _withinDepthBound(json['path'] as String? ?? '');

  bool _withinDepthBound(String path) {
    if (captureRootLevels.isEmpty) return true;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    final ownLevel = segments.length;
    for (final rootUid in captureRootUids) {
      final rootLevel = captureRootLevels[rootUid];
      if (rootLevel != null &&
          segments.contains(rootUid) &&
          ownLevel - rootLevel <= 1) {
        return true;
      }
    }
    return false;
  }

  /// Removes any ALREADY-STORED org unit that no longer satisfies the
  /// depth bound — needed because delta sync (unlike a full sync,
  /// which wipes and rebuilds) only adds/updates and removes
  /// server-deleted rows; it has no way to notice "this device's
  /// existing rows predate a policy that now excludes them." Call
  /// this once [captureRootLevels] is set, after syncAll/syncDelta, so
  /// a device that synced before this bound existed converges to it
  /// on its very next sync rather than only on a full re-sync.
  Future<int> pruneOutOfScope() async {
    if (captureRootLevels.isEmpty) return 0;
    final rows = await db.select(db.orgUnitsTable).get();
    final outOfScope = [
      for (final r in rows)
        if (!_withinDepthBound(r.path)) r.uid,
    ];
    if (outOfScope.isEmpty) return 0;
    return (db.delete(db.orgUnitsTable)..where((t) => t.uid.isIn(outOfScope)))
        .go();
  }

  @override
  String get resource => 'organisationUnits';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'parent[id,name]', 'path', 'code',
        'openingDate', 'closedDate', 'lastUpdated',
      ];

  @override
  TableInfo<Table, OrgUnit> get table => db.orgUnitsTable;

  @override
  Column<String> get uidColumn => db.orgUnitsTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.orgUnitsTable.lastUpdated;

  @override
  Insertable<OrgUnit> companionFromJson(Map<String, dynamic> json) {
    return OrgUnitsTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      parentUid: Value(json['parent']?['id'] as String?),
      parentName: Value(json['parent']?['name'] as String?),
      path: json['path'] as String? ?? '',
      code: Value(json['code'] as String?),
      openingDate: Value(json['openingDate'] as String?),
      closedDate: Value(json['closedDate'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }

  Future<List<OrgUnit>> getChildren(String parentUid) {
    return (db.select(db.orgUnitsTable)
          ..where((t) => t.parentUid.equals(parentUid))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<OrgUnit>> getCaptureRoots() {
    return (db.select(db.orgUnitsTable)
          ..where((t) => t.isUserCaptureRoot.equals(true)))
        .get();
  }
}

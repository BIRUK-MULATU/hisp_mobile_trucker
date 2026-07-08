import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

/// Attribute DEFINITIONS (/api/attributes). The values live embedded in
/// their host objects and are written per-host via [writeAttributeValues].
class AttributeResource extends MetadataResource<AttributeDef> {
  AttributeResource(super.db);

  @override
  String get resource => 'attributes';

  @override
  List<String> get fields => ['id', 'name', 'displayName', 'valueType'];

  @override
  TableInfo<Table, AttributeDef> get table => db.attributesTable;

  @override
  Column<String> get uidColumn => db.attributesTable.uid;

  // No lastUpdated column -> null -> syncDelta falls back to full sync.
  @override
  Column<DateTime>? get lastUpdatedColumn => null;

  @override
  Insertable<AttributeDef> companionFromJson(Map<String, dynamic> json) {
    return AttributesTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      valueType: json['valueType'] as String? ?? 'TEXT',
    );
  }
}

/// The fields= fragment every attribute-bearing host must include so the
/// embedded values come back: 'attributeValues[value,attribute[id]]'.
const attributeValuesField = 'attributeValues[value,attribute[id]]';

/// Fan the embedded attributeValues of ONE host object into the generic
/// attribute_values table, tagged with [objectType]. Call inside the
/// host's saveAll, in the same transaction, AFTER deleting this host's
/// old attribute rows (wholesale rewrite — keeps them fresh when the
/// host's lastUpdated ticks).
///
///   await b_deleteOldFor(objectType, hostUid);   // caller does this
///   writeAttributeValues(b, objectType, hostUid, hostJson);
void writeAttributeValues(
  Batch b,
  AppDatabase db,
  String objectType,
  String hostUid,
  Map<String, dynamic> hostJson,
) {
  for (final av in (hostJson['attributeValues'] as List? ?? [])
      .cast<Map<String, dynamic>>()) {
    final attrUid = av['attribute']?['id'] as String?;
    final value = av['value'] as String?;
    if (attrUid == null || value == null) continue;
    b.insert(
      db.attributeValuesTable,
      AttributeValuesTableCompanion.insert(
        objectType: objectType,
        objectUid: hostUid,
        attributeUid: attrUid,
        value: value,
      ),
    );
  }
}

/// Read helper: attribute values of one host object, as
/// attributeUid -> value. Local, like every read.
extension AttributeValueReads on AppDatabase {
  Future<Map<String, String>> attributeValuesOf(
      String objectType, String objectUid) async {
    final rows = await (select(attributeValuesTable)
          ..where((t) =>
              t.objectType.equals(objectType) &
              t.objectUid.equals(objectUid)))
        .get();
    return {for (final r in rows) r.attributeUid: r.value};
  }

  /// REVERSE lookup: uids of hosts of [objectType] whose [attributeUid]
  /// equals [value] exactly. Feed the result to that type's resource,
  /// e.g. dataSetResource.getByIds(await db.hostUidsByAttribute(...)).
  Future<List<String>> hostUidsByAttribute({
    required String objectType,
    required String attributeUid,
    required String value,
  }) async {
    final rows = await (select(attributeValuesTable)
          ..where((t) =>
              t.objectType.equals(objectType) &
              t.attributeUid.equals(attributeUid) &
              t.value.equals(value)))
        .get();
    return [for (final r in rows) r.objectUid];
  }

  /// Same, but substring/LIKE match (case-insensitive). Use for search
  /// boxes; use the exact version for coded attributes.
  Future<List<String>> hostUidsByAttributeLike({
    required String objectType,
    required String attributeUid,
    required String pattern,
  }) async {
    final rows = await (select(attributeValuesTable)
          ..where((t) =>
              t.objectType.equals(objectType) &
              t.attributeUid.equals(attributeUid) &
              t.value.lower().like('%${pattern.toLowerCase()}%')))
        .get();
    return [for (final r in rows) r.objectUid];
  }
}
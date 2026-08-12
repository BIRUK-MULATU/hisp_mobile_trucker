import '../database/app_database.dart';
import '../metadata/attribute.dart';
import '../metadata/data_element_group.dart';

/// Resolves DHIS2 "controller data elements": a Boolean data element
/// tagged with the custom attribute "Controller Data Element
/// Attribute" == "true", whose current value decides whether the
/// OTHER data elements in its data element group show up in the
/// form. E.g. "RMNCH - Delivery services provided" (Yes/No) gates
/// every other element in its "CG_Delivery Services" group — "No"
/// hides them (and their entered data is cleared by the caller).
///
/// Purely a metadata lookup — reads the same synced tables every
/// other MetadataResource reads, no network involved.
class ControllerElementService {
  ControllerElementService(this._db);

  final AppDatabase _db;

  static const _controllerAttributeName = 'Controller Data Element Attribute';

  /// For every [elementUids] entry that is a controller, the ids of
  /// the other data elements in its group (never including itself).
  /// A controller whose group turns out to have no other members is
  /// left out entirely — it gates nothing.
  Future<Map<String, List<String>>> controllersFor(
      List<String> elementUids) async {
    final attrUid = await _db.attributeUidByName(_controllerAttributeName);
    if (attrUid == null) return const {};

    final controllerUids = (await _db.hostUidsByAttribute(
      objectType: 'dataElement',
      attributeUid: attrUid,
      value: 'true',
    ))
        .toSet()
      ..retainAll(elementUids);
    if (controllerUids.isEmpty) return const {};

    final groupResource = DataElementGroupResource(_db);
    final result = <String, List<String>>{};
    for (final uid in controllerUids) {
      final groupUids = await groupResource.groupUidsFor(uid);
      final controlled = <String>{};
      for (final g in groupUids) {
        controlled.addAll(await groupResource.dataElementUids(g));
      }
      controlled.remove(uid);
      if (controlled.isNotEmpty) result[uid] = controlled.toList();
    }
    return result;
  }
}

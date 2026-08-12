import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../metadata/attribute.dart';
import '../metadata/option.dart';

/// Resolves DHIS2 "labeled" data elements: a data element tagged with
/// the custom attribute "Label Data Element Groups" carries a CODE
/// that resolves — via the option set flagged "Label Option Set" ==
/// "true" (a controlled vocabulary of KPI/indicator names) — to a
/// friendly label. E.g. "MAT_LAFP Removal within 6 Months of
/// Insertion" is tagged "RMH_FP_LAFPPR", which resolves to "Premature
/// Removal of Long term family planning methods (PRLAFP)".
///
/// Several data elements can share one code — e.g. an aggregated and
/// non-aggregated pair of the same indicator — in which case they're
/// all meant to be grouped in the form under that one shared label.
/// Purely a metadata lookup, same as ControllerElementService.
class ElementLabelService {
  ElementLabelService(this._db);

  final AppDatabase _db;

  static const _labelGroupAttributeName = 'Label Data Element Groups';
  static const _labelOptionSetAttributeName = 'Label Option Set';

  /// elementUid -> resolved label text, for every [elementUids] entry
  /// that carries a recognized label code. Elements with no label —
  /// or a code that doesn't match any option in the label option set
  /// — are left out entirely.
  Future<Map<String, String>> labelsFor(List<String> elementUids) async {
    final groupAttrUid = await _db.attributeUidByName(_labelGroupAttributeName);
    if (groupAttrUid == null) return const {};

    final optionSetAttrUid =
        await _db.attributeUidByName(_labelOptionSetAttributeName);
    if (optionSetAttrUid == null) return const {};
    final labelSetUids = await _db.hostUidsByAttribute(
      objectType: 'optionSet',
      attributeUid: optionSetAttrUid,
      value: 'true',
    );
    if (labelSetUids.isEmpty) return const {};

    // code -> display label, across every option set flagged as the
    // label source (normally just one).
    final optionResource = OptionResource(_db);
    final codeToLabel = <String, String>{};
    for (final setUid in labelSetUids) {
      for (final o in await optionResource.getByOptionSet(setUid)) {
        codeToLabel[o.code] = o.displayName;
      }
    }
    if (codeToLabel.isEmpty) return const {};

    final rows = await (_db.select(_db.attributeValuesTable)
          ..where((t) =>
              t.objectType.equals('dataElement') &
              t.attributeUid.equals(groupAttrUid)))
        .get();
    final codeByElement = {for (final r in rows) r.objectUid: r.value};

    final result = <String, String>{};
    for (final uid in elementUids) {
      final code = codeByElement[uid];
      if (code == null) continue;
      final label = codeToLabel[code];
      if (label != null) result[uid] = label;
    }
    return result;
  }
}

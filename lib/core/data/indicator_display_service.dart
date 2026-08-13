import '../database/app_database.dart';
import '../metadata/attribute.dart';

/// One DHIS2 Indicator flagged "Indicator displayable" == "true" —
/// shown read-only in the data-entry form (never sent to the server),
/// computed live with the same expression engine ValidationService
/// uses.
class DisplayIndicator {
  const DisplayIndicator({
    required this.name,
    required this.numerator,
    required this.denominator,
    required this.factor,
  });

  final String name;
  final String numerator;
  final String denominator;
  final int factor;
}

/// Resolves which "displayable" indicators belong in a loaded form,
/// and where: each is anchored to the FIRST data element — in the
/// form's own order — that its numerator/denominator actually
/// reference. E.g. "MAT_New and Repeat Contraceptive Acceptors by
/// Age" sums #{MAT_Contraceptive New Acceptors By Age} +
/// #{...Repeat Acceptors By Age}, so it renders directly above
/// whichever of those two appears first in the form — matching how
/// the reference layout places it.
class IndicatorDisplayService {
  IndicatorDisplayService(this._db);

  final AppDatabase _db;

  static const _displayableAttributeName = 'Indicator displayable';
  static final _operandRe = RegExp(r'#\{([A-Za-z0-9]{11})');

  /// elementUid -> the indicator(s) anchored to it, each ready to be
  /// evaluated against whatever local values the caller has.
  Future<Map<String, List<DisplayIndicator>>> displayIndicatorsFor(
      List<String> elementUids) async {
    final attrUid = await _db.attributeUidByName(_displayableAttributeName);
    if (attrUid == null) return const {};

    final indicatorUids = await _db.hostUidsByAttribute(
      objectType: 'indicator',
      attributeUid: attrUid,
      value: 'true',
    );
    if (indicatorUids.isEmpty) return const {};

    final indicators = await (_db.select(_db.indicatorsTable)
          ..where((t) => t.uid.isIn(indicatorUids)))
        .get();

    final positionOf = {
      for (var i = 0; i < elementUids.length; i++) elementUids[i]: i,
    };

    final result = <String, List<DisplayIndicator>>{};
    for (final ind in indicators) {
      final refs = [
        for (final m
            in _operandRe.allMatches('${ind.numerator} ${ind.denominator}'))
          m.group(1)!,
      ];
      // The element that appears EARLIEST in the form among every
      // element this indicator's formula references.
      String? anchor;
      var bestPos = elementUids.length;
      for (final ref in refs) {
        final pos = positionOf[ref];
        if (pos != null && pos < bestPos) {
          bestPos = pos;
          anchor = ref;
        }
      }
      if (anchor == null) continue; // none of its operands are in this form

      (result[anchor] ??= []).add(DisplayIndicator(
        name: ind.displayName,
        numerator: ind.numerator,
        denominator: ind.denominator,
        factor: ind.indicatorTypeFactor,
      ));
    }
    return result;
  }
}

import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../utils/app_logger.dart';

/// One snapshot from DHIS2's OWN audit trail for a data value — the
/// value as it stood right after a CREATE/UPDATE/DELETE, who made it,
/// and when. This is authoritative server history: it reflects edits
/// from every client that has ever touched the value (web, other
/// devices), not just this phone.
///
/// NOTE: DHIS2 only records these when data value auditing is enabled
/// server-side (a system setting) — an empty result does not prove
/// nothing ever changed, only that nothing was audited.
class ServerDataValueAudit {
  const ServerDataValueAudit({
    required this.dataElementUid,
    required this.period,
    required this.orgUnitUid,
    required this.categoryOptionComboUid,
    required this.attributeOptionComboUid,
    required this.value,
    required this.modifiedBy,
    required this.created,
    required this.auditType,
  });

  final String dataElementUid;
  final String period;
  final String orgUnitUid;
  final String categoryOptionComboUid;
  final String attributeOptionComboUid;
  final String? value;
  final String? modifiedBy;
  final DateTime? created;

  /// One of CREATE, UPDATE, DELETE (as returned by the server).
  final String auditType;

  factory ServerDataValueAudit.fromJson(Map<String, dynamic> json) {
    return ServerDataValueAudit(
      dataElementUid: _uid(json['dataElement']) ?? '',
      period: _uid(json['period']) ?? '',
      orgUnitUid: _uid(json['organisationUnit']) ?? '',
      categoryOptionComboUid: _uid(json['categoryOptionCombo']) ?? '',
      attributeOptionComboUid: _uid(json['attributeOptionCombo']) ?? '',
      value: json['value']?.toString(),
      modifiedBy: _uid(json['modifiedBy']),
      created: DateTime.tryParse(_uid(json['created']) ?? ''),
      auditType: _uid(json['auditType']) ?? 'UPDATE',
    );
  }

  /// Some DHIS2 versions/endpoints expand audit references into
  /// `{"id": "...", "name": "..."}` objects instead of plain uid
  /// strings — accept either so a server-side shape change doesn't
  /// crash parsing.
  static String? _uid(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is Map) return field['id'] as String? ?? field['uid'] as String?;
    return field.toString();
  }
}

/// Reads DHIS2's built-in audit trail (`/api/audits/dataValue`) —
/// server-authoritative history, as opposed to [AuditLogStore] which
/// only ever knows about edits made on this device. Scoped to ONE
/// cell only (see [fetchForCell]) — the audit trail lives inside each
/// data element's category combo, same as DHIS2's own entry apps, not
/// as a device- or org-unit-wide log.
class ServerAuditService {
  ServerAuditService(this._api);

  final ApiClient _api;

  /// History for ONE cell — a data element's single category option
  /// combo, at a period and org unit. This is the query DHIS2's own
  /// entry apps run when you open "Show history" on a cell: narrow
  /// enough that even a server with a long audit table answers fast.
  /// [comboParams] is the cc/cp pair from [resolveCcCpParams] — empty
  /// for the default combo, in which case every combo of the element
  /// is returned and the caller filters by [ServerDataValueAudit
  /// .categoryOptionComboUid] itself.
  Future<List<ServerDataValueAudit>?> fetchForCell({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    Map<String, String> comboParams = const {},
    int pageSize = 50,
  }) {
    return _fetch({
      'de': dataElementUid,
      'pe': period,
      'ou': orgUnitUid,
      ...comboParams,
      'pageSize': pageSize,
    });
  }

  Future<List<ServerDataValueAudit>?> _fetch(
      Map<String, dynamic> queryParameters) async {
    try {
      final res = await _api.get('/api/audits/dataValue.json',
          queryParameters: queryParameters);
      final data = res.data as Map<String, dynamic>;
      final rows = (data['dataValueAudits'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final audits = [
        for (final r in rows) ServerDataValueAudit.fromJson(r),
      ]..sort((a, b) {
          final ac = a.created;
          final bc = b.created;
          if (ac == null || bc == null) return 0;
          return bc.compareTo(ac);
        });
      return audits;
    } on DioException catch (e) {
      log.e('[audit] server audit fetch failed: ${e.message}');
      return null;
    } catch (e) {
      log.e('[audit] server audit response could not be parsed: $e '
          '(params: $queryParameters)');
      return null;
    }
  }
}

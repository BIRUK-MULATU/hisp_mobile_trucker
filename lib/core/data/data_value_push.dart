import 'package:dio/dio.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'data_value_store.dart';

/// Outcome of one dataValueSets push.
class DataValuePushResult {
  const DataValuePushResult({
    this.accepted = 0,
    this.rejected = 0,
    this.transportFailed = false,
  });

  /// Values the server accepted — marked synced.
  final int accepted;

  /// Values the server rejected — marked error with the conflict text.
  final int rejected;

  /// Nothing reached the server; every value stays pending.
  final bool transportFailed;
}

/// POST [values] as ONE dataValueSets import and settle each row's sync
/// state from the server's verdict.
///
/// DHIS2 2.38+ answers an import that has conflicts with HTTP 409 (so
/// dio throws) — but the body is still the full ImportSummary, so the
/// 2xx and 409 paths feed the same parser. Rejected rows are identified
/// exactly via the summary's per-conflict `indexes` / top-level
/// `rejectedIndexes`, which index into the payload array (same order as
/// [values]); servers too old to send indexes fall back to a substring
/// match on the conflict text. Only a transport-level failure (no
/// ImportSummary body) leaves values pending for a later retry.
Future<DataValuePushResult> pushDataValueBatch({
  required ApiClient api,
  required DataValueStore store,
  required List<DataValue> values,
  String logTag = 'dataValues',
  void Function(Response res)? onResponse,
}) async {
  if (values.isEmpty) return const DataValuePushResult();

  final payload = {
    'dataValues': [
      for (final v in values)
        {
          'dataElement': v.dataElementUid,
          'period': v.period,
          'orgUnit': v.orgUnitUid,
          'categoryOptionCombo': v.categoryOptionComboUid,
          'attributeOptionCombo': v.attributeOptionComboUid,
          'value': v.value ?? '',
          if (v.comment != null) 'comment': v.comment,
        }
    ],
  };

  Map<String, dynamic> body;
  try {
    final res = await api.post('/api/dataValueSets.json',
        data: payload,
        queryParameters: {
          'importStrategy': 'CREATE_AND_UPDATE',
          'atomicMode': 'NONE',
        });
    onResponse?.call(res);
    body = res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    final res = e.response;
    final data = res?.data;
    if (res != null && res.statusCode == 409 && data is Map<String, dynamic>) {
      onResponse?.call(res);
      body = data;
    } else {
      log.e('[$logTag] push failed, values stay pending: ${e.message}');
      return const DataValuePushResult(transportFailed: true);
    }
  }

  final summary = (body['response'] ?? body) as Map<String, dynamic>;
  final conflicts =
      (summary['conflicts'] as List? ?? const []).cast<Map<String, dynamic>>();
  final ignored =
      ((summary['importCount'] ?? const {}) as Map<String, dynamic>)['ignored'] ??
          0;

  if (conflicts.isEmpty && ignored == 0) {
    for (final v in values) {
      await store.markSynced(v);
    }
    return DataValuePushResult(accepted: values.length);
  }

  // Rejections by payload index — exact per-value verdicts.
  final reasons = <int, List<String>>{};
  for (final c in conflicts) {
    final msg =
        (c['value'] ?? c['errorCode'] ?? 'Rejected by server').toString();
    for (final i in (c['indexes'] as List? ?? const [])) {
      if (i is int && i >= 0 && i < values.length) {
        (reasons[i] ??= []).add(msg);
      }
    }
  }
  for (final i in (summary['rejectedIndexes'] as List? ?? const [])) {
    if (i is int && i >= 0 && i < values.length) {
      reasons[i] ??= ['Rejected by server'];
    }
  }

  var rejected = 0;
  if (reasons.isNotEmpty) {
    for (var i = 0; i < values.length; i++) {
      final why = reasons[i];
      if (why == null) {
        await store.markSynced(values[i]);
      } else {
        await store.markError(values[i], why.join('; '));
        rejected++;
      }
    }
  } else {
    // No index info — heuristic match on the conflict text.
    final conflictText =
        conflicts.map((c) => '${c['object']} ${c['value']}').join(' ');
    for (final v in values) {
      final hit = conflictText.contains(v.dataElementUid) &&
          conflictText.contains(v.period);
      if (hit) {
        await store.markError(v, conflictText);
        rejected++;
      } else {
        await store.markSynced(v);
      }
    }
  }

  if (rejected > 0) {
    log.w('[$logTag] $rejected of ${values.length} values rejected by server');
  }
  return DataValuePushResult(
      accepted: values.length - rejected, rejected: rejected);
}

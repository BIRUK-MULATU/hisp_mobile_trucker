import 'package:dio/dio.dart';

import '../database/app_database.dart';
import '../metadata/data_element.dart';
import '../metadata/option.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'data_value_store.dart';
import 'value_type_validator.dart';

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
/// Values per POST. Weeks of offline work must not go up as one giant
/// request — a mid-transfer drop on a field connection would waste the
/// whole upload instead of one slice.
const _maxBatchSize = 500;

/// True when a queued row carries neither a value nor a comment — i.e.
/// the user cleared the cell. Such a row must go up as a DELETION, not
/// as `value: ""`: DHIS2 rejects an empty value with E7610
/// ("data value or comment not specified"), whereas a `deleted: true`
/// entry removes the server value if it exists and is silently ignored
/// (no conflict, no rejected index) if it never did.
bool _isClear(DataValue v) =>
    (v.value == null || v.value!.trim().isEmpty) &&
    (v.comment == null || v.comment!.trim().isEmpty);

Map<String, dynamic> _payloadEntry(DataValue v) {
  final clear = _isClear(v);
  return {
    'dataElement': v.dataElementUid,
    'period': v.period,
    'orgUnit': v.orgUnitUid,
    'categoryOptionCombo': v.categoryOptionComboUid,
    'attributeOptionCombo': v.attributeOptionComboUid,
    // Trim: the entry form already trims on save, but a value queued by
    // an older build (or any other path) must never go up with stray
    // whitespace the server would store verbatim or reject.
    'value': v.value?.trim() ?? '',
    if (v.comment != null) 'comment': v.comment?.trim(),
    if (clear) 'deleted': true,
  };
}

/// valueTypes whose client check ([validateDataValue]) exactly matches
/// the server's own import rules (E7619 boolean, E7620 numeric, E7621
/// option) — safe to settle locally. DATE / PHONE_NUMBER / EMAIL / TEXT
/// are deliberately excluded: the server stays the authority for those.
const _locallyScreenedTypes = {
  'NUMBER',
  'INTEGER',
  'INTEGER_POSITIVE',
  'INTEGER_NEGATIVE',
  'INTEGER_ZERO_OR_POSITIVE',
  'PERCENTAGE',
  'UNIT_INTERVAL',
  'BOOLEAN',
  'TRUE_ONLY',
};

class _ScreenResult {
  _ScreenResult(this.sendable, this.rejected);

  /// Rows to actually POST (valid, or empty = will go up as a deletion).
  final List<DataValue> sendable;

  /// Rows that fail their own valueType — mapped to the readable reason.
  final Map<DataValue, String> rejected;
}

/// Pre-flight every queued value against its element's valueType /
/// option set. A value that can't possibly be accepted (text in a
/// number field, a code outside the option set, …) is settled as an
/// error HERE — with the same message the user would eventually get
/// from the server — instead of spending a round trip, and without
/// poisoning the valid rows sharing its batch.
Future<_ScreenResult> _screenBeforePush(
    DataValueStore store, List<DataValue> values) async {
  final db = store.db;
  final deUids = {for (final v in values) v.dataElementUid}.toList();

  Map<String, DataElement> byUid;
  final codesBySet = <String, Set<String>>{};
  try {
    final elements = await DataElementResource(db).getByIds(deUids);
    byUid = {for (final e in elements) e.uid: e};
    final optionResource = OptionResource(db);
    for (final e in elements) {
      final set = e.optionSetUid;
      if (set != null && !codesBySet.containsKey(set)) {
        final opts = await optionResource.getByOptionSet(set);
        codesBySet[set] = {for (final o in opts) o.code};
      }
    }
  } catch (e) {
    // Metadata unreadable — skip screening entirely, let the server
    // judge. Screening is an optimisation, never a gate.
    log.w('[dataValues] pre-push screen skipped: $e');
    return _ScreenResult(values, const {});
  }

  final sendable = <DataValue>[];
  final rejected = <DataValue, String>{};
  for (final v in values) {
    final raw = v.value?.trim() ?? '';
    final element = byUid[v.dataElementUid];
    if (raw.isEmpty || element == null) {
      sendable.add(v); // a clear, or nothing local to judge against
      continue;
    }
    final codes = element.optionSetUid == null
        ? null
        : codesBySet[element.optionSetUid];
    final hasCodes = codes != null && codes.isNotEmpty;
    if (!hasCodes &&
        !_locallyScreenedTypes.contains(element.valueType.toUpperCase())) {
      sendable.add(v); // server is the authority for this type
      continue;
    }
    final problem = validateDataValue(element.valueType, raw, optionCodes: codes);
    if (problem == null) {
      sendable.add(v);
    } else {
      rejected[v] = problem;
    }
  }
  return _ScreenResult(sendable, rejected);
}

Future<DataValuePushResult> pushDataValueBatch({
  required ApiClient api,
  required DataValueStore store,
  required List<DataValue> values,
  String logTag = 'dataValues',
  void Function(Response res)? onResponse,
}) async {
  if (values.isEmpty) return const DataValuePushResult();

  final screen = await _screenBeforePush(store, values);
  for (final e in screen.rejected.entries) {
    await store.markError(e.key, e.value);
  }
  if (screen.rejected.isNotEmpty) {
    log.w('[$logTag] ${screen.rejected.length} value(s) settled as error '
        'before push — invalid for their type');
  }
  if (screen.sendable.isEmpty) {
    return DataValuePushResult(rejected: screen.rejected.length);
  }

  final r = await _pushScreenedBatch(
    api: api,
    store: store,
    values: screen.sendable,
    logTag: logTag,
    onResponse: onResponse,
  );
  return DataValuePushResult(
    accepted: r.accepted,
    rejected: r.rejected + screen.rejected.length,
    transportFailed: r.transportFailed,
  );
}

Future<DataValuePushResult> _pushScreenedBatch({
  required ApiClient api,
  required DataValueStore store,
  required List<DataValue> values,
  required String logTag,
  void Function(Response res)? onResponse,
}) async {
  if (values.isEmpty) return const DataValuePushResult();

  // Chunk oversized queues; each slice settles independently, so a
  // failure partway leaves only the unsent slices pending.
  if (values.length > _maxBatchSize) {
    var accepted = 0, rejected = 0;
    for (var start = 0; start < values.length; start += _maxBatchSize) {
      final slice = values.sublist(
          start,
          start + _maxBatchSize > values.length
              ? values.length
              : start + _maxBatchSize);
      final r = await _pushScreenedBatch(
          api: api,
          store: store,
          values: slice,
          logTag: logTag,
          onResponse: onResponse);
      accepted += r.accepted;
      rejected += r.rejected;
      if (r.transportFailed) {
        return DataValuePushResult(
            accepted: accepted, rejected: rejected, transportFailed: true);
      }
    }
    return DataValuePushResult(accepted: accepted, rejected: rejected);
  }

  final payload = {
    'dataValues': [for (final v in values) _payloadEntry(v)],
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
      // A bare rejected index against a cleared row with no matching
      // conflict is just DHIS2 counting "nothing to delete" — that row
      // is already in the state we want, so let it settle as synced
      // rather than surfacing a phantom error.
      if (reasons[i] == null && _isClear(values[i])) continue;
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

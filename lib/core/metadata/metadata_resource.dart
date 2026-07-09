import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';

/// Shared by every companionFromJson: DHIS2 sends ISO-8601 lastUpdated.
Value<DateTime?> lastUpdatedFrom(Map<String, dynamic> json) =>
    Value(DateTime.tryParse(json['lastUpdated'] as String? ?? ''));

/// Base class for all DHIS2 metadata resources — the Dart translation of
/// your MetadataResource (TS/IndexedDB) pattern.
///
/// Each subclass declares: resource name, fields= selection, its drift
/// table, and how JSON becomes a row. Everything else — fetch, chunked
/// fetch-by-ids, lastUpdated map, save, getById, getAll, deleteById —
/// is inherited.
///
/// [Row] is the drift-generated row class (DataElement, DataSet, ...),
/// so every result is fully typed with autocomplete.
abstract class MetadataResource<Row> {
  MetadataResource(this.db);

  final AppDatabase db;

  // ── Subclass contract (≙ your static resource / getFields / fromJSON) ──

  /// DHIS2 endpoint name, e.g. 'dataElements'. Also the JSON list key.
  String get resource;

  /// The fields= selection — fetch exactly what the table stores.
  List<String> get fields;

  /// The drift table this resource persists to.
  TableInfo<Table, Row> get table;

  /// The uid column of this resource's table. The base derives every
  /// uid lookup from it (equals, isIn) — one member instead of many.
  Column<String> get uidColumn;

  /// The lastUpdated column — the basis of delta sync. Return null for
  /// resources whose table has no lastUpdated; syncDelta then falls back
  /// to a full syncAll for that resource.
  Column<DateTime>? get lastUpdatedColumn;

  /// JSON object -> insertable row (≙ fromJSON). Throwing on malformed
  /// input is correct — better loud at sync than silent nulls at entry.
  Insertable<Row> companionFromJson(Map<String, dynamic> json);

  /// Basic criteria an object must meet to be worth storing. Objects
  /// failing this are SKIPPED with a warning (not an error) — for
  /// server-side orphans that can never be used (e.g. an option
  /// without an optionSet). Default: everything is valid. Only
  /// override for genuinely ignorable defects; a missing field that
  /// would break rendering later should FAIL loudly instead (by
  /// letting companionFromJson throw).
  bool isValid(Map<String, dynamic> json) => true;

  /// Server-side filters applied to the LIST requests (fetchJson +
  /// fetchLastUpdated) — the scope cap for oversized resources. More
  /// than one filter is combined with rootJunction=OR. NOT applied to
  /// fetchByIds: delta's stale set is already computed from the
  /// filtered lastUpdated list, so id fetches stay in scope by
  /// construction.
  List<String> get filters => const [];

  Map<String, dynamic> _withFilters(Map<String, dynamic> params) {
    if (filters.isEmpty) return params;
    return {
      ...params,
      'filter': filters,
      if (filters.length > 1) 'rootJunction': 'OR',
    };
  }

  // ── Local (SQLite) — inherited by every resource ──

  Future<List<Row>> getAll() => db.select(table).get();

  Future<Row?> getById(String uid) =>
      (db.select(table)..where((_) => uidColumn.equals(uid)))
          .getSingleOrNull();

  /// LOCAL batch lookup — the second half of the id-list navigation
  /// style: relationship accessors return uids, business logic resolves
  /// them here. (Network counterpart: fetchByIds.)
  Future<List<Row>> getByIds(List<String> uids) =>
      (db.select(table)..where((_) => uidColumn.isIn(uids))).get();

  Future<int> deleteById(String uid) =>
      (db.delete(table)..where((_) => uidColumn.equals(uid))).go();

  Future<int> deleteByIds(List<String> uids) =>
      (db.delete(table)..where((_) => uidColumn.isIn(uids))).go();

  /// DELTA sync: one cheap id+lastUpdated request, then fetch ONLY the
  /// new/changed objects and delete the server-removed ones. The routine
  /// path for every login-while-online after the first.
  ///
  /// Timestamp note: drift stores DateTime at second precision while the
  /// server sends milliseconds — comparison uses a 1s tolerance so
  /// unchanged objects are not perpetually re-fetched.
  Future<({int updated, int deleted})> syncDelta(ApiClient api) async {
    // Resources without a lastUpdated column can't do delta — full sync.
    final lastUpdatedCol = lastUpdatedColumn;
    if (lastUpdatedCol == null) {
      final n = await syncAll(api);
      return (updated: n, deleted: 0);
    }

    final remote = await fetchLastUpdated(api);

    final rows = await (db.selectOnly(table)
          ..addColumns([uidColumn, lastUpdatedCol]))
        .get();
    final local = <String, DateTime?>{
      for (final r in rows) r.read(uidColumn)!: r.read(lastUpdatedCol),
    };

    final stale = <String>[
      for (final e in remote.entries)
        if (_isNewer(e.value, local[e.key]) || !local.containsKey(e.key))
          e.key,
    ];
    final removed = [
      for (final uid in local.keys)
        if (!remote.containsKey(uid)) uid,
    ];

    if (stale.isNotEmpty) {
      await saveAll(await fetchByIds(api, stale));
    }
    if (removed.isNotEmpty) {
      await deleteByIds(removed);
    }
    log.i('[$resource] syncDelta: ${stale.length} updated, '
        '${removed.length} deleted (remote=${remote.length})');
    return (updated: stale.length, deleted: removed.length);
  }

  static bool _isNewer(String remoteIso, DateTime? local) {
    if (local == null) return true;
    final remote = DateTime.tryParse(remoteIso);
    if (remote == null) return true;
    return remote.isAfter(local.add(const Duration(seconds: 1)));
  }

  /// Upsert a batch of decoded JSON objects in one transaction.
  /// Empty input is a no-op — an instance legitimately may have zero
  /// objects of a resource (e.g. no optionSets configured).
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      log.d('[$resource] saveAll: nothing to save');
      return;
    }
    final valid = <Map<String, dynamic>>[];
    final skipped = <String>[];
    for (final item in items) {
      if (isValid(item)) {
        valid.add(item);
      } else {
        skipped.add(item['id']?.toString() ?? '(no id)');
      }
    }
    if (skipped.isNotEmpty) {
      log.w('[$resource] skipped ${skipped.length} invalid object(s): '
          '${skipped.join(', ')}');
    }
    if (valid.isEmpty) return;
    await db.batch((b) {
      b.insertAllOnConflictUpdate(table, [
        for (final item in valid) _companionOrExplain(item),
      ]);
    });
  }

  /// Wraps companionFromJson so a parse failure reports WHICH object
  /// broke and what it looked like — not just a null-method error.
  Insertable<Row> _companionOrExplain(Map<String, dynamic> item) {
    try {
      return companionFromJson(item);
    } catch (e) {
      log.e('[$resource] failed to parse object '
          '${item['id'] ?? '(no id)'} — offending JSON:\n$item');
      rethrow;
    }
  }

  // ── Remote (DHIS2 API) — inherited by every resource ──

  /// GET /api/{resource}.json?fields=...&paging=false
  ///
  /// Empty instances return {"resource": []} or omit the key entirely —
  /// both yield []. A non-JSON body (proxy error page, redirect to a
  /// login screen) fails LOUDLY with the actual type, not a cryptic
  /// cast error deep in parsing.
  Future<List<Map<String, dynamic>>> fetchJson(ApiClient api) async {
    final Response res = await api.get('/api/$resource.json',
        queryParameters:
            _withFilters({'fields': fields.join(','), 'paging': 'false'}));
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('[$resource] expected a JSON object, got '
          '${data.runtimeType} — is the server URL correct and the '
          'response really JSON?');
    }
    return (data[resource] as List? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// fetch + saveAll in one call — the common sync move.
  Future<int> syncAll(ApiClient api) async {
    log.i('[$resource] syncAll: fetching ...');
    final items = await fetchJson(api);
    await saveAll(items);
    log.i('[$resource] syncAll: saved ${items.length}');
    return items.length;
  }

  /// uid -> lastUpdated timestamp for the whole resource (cheap request;
  /// the basis for delta sync: compare, then fetchByIds the stale ones).
  Future<Map<String, String>> fetchLastUpdated(ApiClient api) async {
    final Response res = await api.get('/api/$resource.json',
        queryParameters: _withFilters(
            {'fields': 'id,lastUpdated', 'paging': 'false'}));
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('[$resource] lastUpdated fetch: non-JSON response');
    }
    final items =
        (data[resource] as List? ?? const []).cast<Map<String, dynamic>>();
    return {
      for (final i in items)
        if (i['lastUpdated'] != null)
          i['id'] as String: i['lastUpdated'] as String,
    };
  }

  /// Fetch specific objects, chunked (long id:in URLs break on proxies).
  Future<List<Map<String, dynamic>>> fetchByIds(ApiClient api, List<String> ids,
      {int chunkSize = 100}) async {
    final all = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
          i, i + chunkSize > ids.length ? ids.length : i + chunkSize);
      final Response res = await api.get('/api/$resource.json',
          queryParameters: {
            'fields': fields.join(','),
            'filter': 'id:in:[${chunk.join(',')}]',
            'paging': 'false',
          });
      all.addAll(((res.data as Map<String, dynamic>)[resource] as List? ?? [])
          .cast<Map<String, dynamic>>());
    }
    return all;
  }
}

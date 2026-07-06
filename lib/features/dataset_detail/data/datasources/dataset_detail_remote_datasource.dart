import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/data_record_entity.dart';
import '../models/data_record_model.dart';

abstract class DatasetDetailRemoteDataSource {
  Future<List<DataRecordModel>> getRecords({
    required String dataSetId,
    required String orgUnitId,
  });
  Future<DataRecordModel> createRecord({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  });
}

class DatasetDetailRemoteDataSourceImpl
    implements DatasetDetailRemoteDataSource {
  final ApiClient _apiClient;

  DatasetDetailRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<DataRecordModel>> getRecords({
    required String dataSetId,
    required String orgUnitId,
  }) async {
    try {
      final now = DateTime.now();
      // dataValueSets requires a period or date range filter (E2002) —
      // use a wide range so every record for this dataset/org unit
      // comes back regardless of period. Day 30 (not 31) is used
      // because the server's Ethiopian calendar caps every month at 30.
      const startDate = '1970-01-01';
      final endDate = '${now.year + 5}-12-30';

      final response = await _apiClient.get(
        '/dataValueSets',
        queryParameters: {
          'dataSet': dataSetId,
          'orgUnit': orgUnitId,
          // Data is captured at facilities BELOW the user's org unit
          // (picked in the org tree selector) — without children=true
          // a region-level query returns nothing.
          'children': 'true',
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (response.statusCode != 200) throw const ServerException();

      // The endpoint returns a FLAT list of values, one entry per
      // cell: {"dataValues": [{period, orgUnit, value, created,
      // lastUpdated, ...}]}. A "record" (one card in the list) is
      // the group of values sharing a period and facility.
      final data = response.data as Map<String, dynamic>;
      final values = data['dataValues'] as List<dynamic>? ?? [];

      final groups = <String, _RecordDates>{};
      final orgUnitIds = <String>{};
      for (final raw in values) {
        final v = raw as Map<String, dynamic>;
        final period = v['period'] as String? ?? '';
        final orgUnit = v['orgUnit'] as String? ?? orgUnitId;
        if (period.isEmpty) continue;
        orgUnitIds.add(orgUnit);
        groups
            .putIfAbsent('$period|$orgUnit', () => _RecordDates())
            .track(v['created'] as String?, v['lastUpdated'] as String?);
      }

      // Completion lives in a separate endpoint. (The dataValueSets
      // response has a completeDataSets block, but it lacks the
      // `completed` flag, so re-opened records would show as
      // completed.) Fetched best-effort: records must still render
      // if this call fails.
      final completedKeys = <String>{};
      try {
        final regResponse = await _apiClient.get(
          '/completeDataSetRegistrations',
          queryParameters: {
            'dataSet': dataSetId,
            'orgUnit': orgUnitId,
            'children': 'true',
            'startDate': startDate,
            'endDate': endDate,
          },
        );
        if (regResponse.statusCode == 200 &&
            regResponse.data is Map<String, dynamic>) {
          final regs = (regResponse.data
                  as Map<String, dynamic>)['completeDataSetRegistrations']
              as List<dynamic>? ??
              [];
          for (final raw in regs) {
            final r = raw as Map<String, dynamic>;
            // `completed: false` marks an explicitly re-opened record.
            if (r['completed'] == false) continue;
            final period = r['period'] as String?;
            final orgUnit = r['organisationUnit'] as String?;
            if (period == null || orgUnit == null) continue;
            completedKeys.add('$period|$orgUnit');
            orgUnitIds.add(orgUnit);
            // Completed without any values entered still deserves
            // a card.
            groups.putIfAbsent('$period|$orgUnit', () => _RecordDates());
          }
        }
      } catch (_) {
        // Ignore — status just shows Incomplete until reachable.
      }

      // Human-readable facility names for "Registered in" on the
      // cards; UIDs are shown if this best-effort lookup fails.
      // Batched — a region can have hundreds of facilities and one
      // id:in:[...] URL with all of them gets rejected by the server.
      final orgUnitNames = <String, String>{};
      const batchSize = 80;
      final allIds = orgUnitIds.toList();
      for (var i = 0; i < allIds.length; i += batchSize) {
        final batch = allIds.sublist(
            i, i + batchSize > allIds.length ? allIds.length : i + batchSize);
        try {
          final ouResponse = await _apiClient.get(
            '/organisationUnits',
            queryParameters: {
              'filter': 'id:in:[${batch.join(',')}]',
              'fields': 'id,displayName',
              'paging': 'false',
            },
          );
          if (ouResponse.statusCode == 200 &&
              ouResponse.data is Map<String, dynamic>) {
            final units = (ouResponse.data
                    as Map<String, dynamic>)['organisationUnits']
                as List<dynamic>? ??
                [];
            for (final raw in units) {
              final u = raw as Map<String, dynamic>;
              final id = u['id'] as String?;
              final name = u['displayName'] as String?;
              if (id != null && name != null) orgUnitNames[id] = name;
            }
          }
        } catch (_) {}
      }

      final records = groups.entries.map((entry) {
        final separator = entry.key.indexOf('|');
        final period = entry.key.substring(0, separator);
        final orgUnit = entry.key.substring(separator + 1);
        return DataRecordModel(
          id: '${dataSetId}_${orgUnit}_$period',
          dataSetId: dataSetId,
          periodId: period,
          orgUnitId: orgUnit,
          orgUnitName: orgUnitNames[orgUnit],
          status: completedKeys.contains(entry.key)
              ? RecordStatus.complete
              : RecordStatus.incomplete,
          createdAt: entry.value.created,
          lastUpdated: entry.value.lastUpdated,
        );
      }).toList()
        // Newest period first; facilities alphabetical within it.
        ..sort((a, b) {
          final byPeriod = b.periodId.compareTo(a.periodId);
          if (byPeriod != 0) return byPeriod;
          return (a.orgUnitName ?? a.orgUnitId)
              .compareTo(b.orgUnitName ?? b.orgUnitId);
        });

      return records;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<DataRecordModel> createRecord({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/dataValueSets',
        data: {
          'dataSet': dataSetId,
          'period': periodId,
          'orgUnit': orgUnitId,
          'dataValues': [],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DataRecordModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dataSetId: dataSetId,
          periodId: periodId,
          orgUnitId: orgUnitId,
        );
      }
      throw const ServerException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

/// Earliest `created` and latest `lastUpdated` across the values
/// that make up one record.
class _RecordDates {
  DateTime? created;
  DateTime? lastUpdated;

  void track(String? createdRaw, String? updatedRaw) {
    final c = createdRaw == null ? null : DateTime.tryParse(createdRaw);
    if (c != null && (created == null || c.isBefore(created!))) {
      created = c;
    }
    final u = updatedRaw == null ? null : DateTime.tryParse(updatedRaw);
    if (u != null && (lastUpdated == null || u.isAfter(lastUpdated!))) {
      lastUpdated = u;
    }
  }
}

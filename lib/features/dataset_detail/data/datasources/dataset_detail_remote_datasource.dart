import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
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
      final response = await _apiClient.get(
        '/dataValueSets',
        queryParameters: {
          'dataSet': dataSetId,
          'orgUnit': orgUnitId,
          // dataValueSets requires a period or date range filter (E2002) —
          // use a wide range so every record for this dataset/org unit
          // comes back regardless of period. Day 30 (not 31) is used
          // because the server's Ethiopian calendar caps every month at 30.
          'startDate': '1970-01-01',
          'endDate': '${now.year + 5}-12-30',
          // dataValues are omitted — the record list never renders
          // them and they dominate the payload for large datasets.
          'fields': 'id,period,orgUnit[id,displayName],dataSet[id],completeDate,created,lastUpdated',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> records =
            data['dataValueSets'] as List<dynamic>? ?? [];
        return records
            .map((e) => DataRecordModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerException();
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

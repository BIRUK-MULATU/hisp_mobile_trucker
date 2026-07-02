import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/data_element_model.dart';

abstract class DataEntryRemoteDataSource {
  Future<List<DataElementModel>> getDataElements({
    required String dataSetId,
  });

  Future<List<DataValueModel>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  Future<void> saveDataValues({
    required List<DataValueModel> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });
}

class DataEntryRemoteDataSourceImpl
    implements DataEntryRemoteDataSource {
  final ApiClient _apiClient;

  DataEntryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<DataElementModel>> getDataElements({
    required String dataSetId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/dataSets/$dataSetId',
        queryParameters: {
          'fields':
              'dataSetElements[dataElement[id,displayName,shortName,'
              'valueType,categoryCombo[id,categoryOptionCombos'
              '[id,displayName,shortName]]]]',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elements =
            data['dataSetElements'] as List<dynamic>? ?? [];
        return elements
            .map((e) => DataElementModel.fromJson(
                e['dataElement'] as Map<String, dynamic>))
            .toList();
      }
      throw const ServerException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<DataValueModel>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      final response = await _apiClient.get(
        '/dataValueSets',
        queryParameters: {
          'dataSet': dataSetId,
          'orgUnit': orgUnitId,
          'period': period,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final values =
            data['dataValues'] as List<dynamic>? ?? [];
        return values
            .map((e) => DataValueModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveDataValues({
    required List<DataValueModel> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      final response = await _apiClient.post(
        '/dataValueSets',
        data: {
          'dataSet': dataSetId,
          'orgUnit': orgUnitId,
          'period': period,
          'dataValues':
              dataValues.map((v) => v.toJson()).toList(),
        },
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw const ServerException(
            message: 'Failed to save data values');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // Registers completion only — deliberately separate from
  // saveDataValues so completing a dataset never re-POSTs data values.
  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      final response = await _apiClient.post(
        '/completeDataSetRegistrations',
        data: {
          'completeDataSetRegistrations': [
            {
              'dataSet': dataSetId,
              'organisationUnit': orgUnitId,
              'period': period,
            },
          ],
        },
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw const ServerException(
            message: 'Failed to complete data set');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

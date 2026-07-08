import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/data_element_model.dart';

abstract class DataEntryRemoteDataSource {
  Future<List<DataElementModel>> getDataElements({
    required String dataSetId,
    String? sectionId,
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

class DataEntryRemoteDataSourceImpl implements DataEntryRemoteDataSource {
  final ApiClient _apiClient;

  DataEntryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<DataElementModel>> getDataElements({
    required String dataSetId,
    String? sectionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/dataSets/$dataSetId',
        queryParameters: {
          // The dataset can override an element's category combo
          // (dataSetElement.categoryCombo) — fetch both and prefer
          // the override, like the DHIS2 web data entry app does.
          // sections[dataElements] carries only ids: the full
          // element metadata still comes from dataSetElements so
          // the override logic stays in one place.
          'fields': 'dataSetElements[categoryCombo[id,'
              'categoryOptionCombos[id,displayName,shortName]],'
              'dataElement[id,displayName,shortName,'
              'valueType,categoryCombo[id,categoryOptionCombos'
              '[id,displayName,shortName]]]],'
              'sections[id,dataElements[id]]',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elements = data['dataSetElements'] as List<dynamic>? ?? [];
        final all = elements.map((e) {
          final json = e['dataElement'] as Map<String, dynamic>;
          final override = e['categoryCombo'] as Map<String, dynamic>?;
          if (override != null) json['categoryCombo'] = override;
          return DataElementModel.fromJson(json);
        }).toList();

        if (sectionId == null) return all;

        // Keep only the section's elements, in the section's own
        // element order (the form order designed on the server).
        final sections = data['sections'] as List<dynamic>? ?? [];
        final section = sections
            .cast<Map<String, dynamic>>()
            .where((s) => s['id'] == sectionId)
            .firstOrNull;
        if (section == null) {
          throw const ServerException(message: 'Section not found in dataset');
        }
        final order = <String, int>{};
        final sectionElements = section['dataElements'] as List<dynamic>? ?? [];
        for (var i = 0; i < sectionElements.length; i++) {
          final id = (sectionElements[i] as Map<String, dynamic>)['id'];
          if (id is String) order[id] = i;
        }
        return all.where((e) => order.containsKey(e.id)).toList()
          ..sort((a, b) => order[a.id]!.compareTo(order[b.id]!));
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
        final values = data['dataValues'] as List<dynamic>? ?? [];
        return values
            .map((e) => DataValueModel.fromJson(e as Map<String, dynamic>))
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
          'dataValues': dataValues.map((v) => v.toJson()).toList(),
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ServerException(message: 'Failed to save data values');
      }
    } on DioException catch (e) {
      // A 409 carries an import summary whose conflicts say exactly
      // which values the server refused — surface those, not the
      // raw exception dump.
      throw ServerException(
          message: _importConflictMessage(e) ?? 'Failed to save data values');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  String? _importConflictMessage(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;
    final response = data['response'];
    if (response is Map<String, dynamic>) {
      final conflicts = response['conflicts'];
      if (conflicts is List && conflicts.isNotEmpty) {
        return conflicts
            .whereType<Map<String, dynamic>>()
            .map((c) => c['value'])
            .whereType<String>()
            .toSet()
            .join('\n');
      }
    }
    final message = data['message'];
    return message is String ? message : null;
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

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ServerException(message: 'Failed to complete data set');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

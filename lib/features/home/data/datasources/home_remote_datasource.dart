import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dataset_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<DataSetModel>> getDataSets();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<DataSetModel>> getDataSets() async {
    try {
      final response = await _apiClient.get(
        '/dataSets',
        queryParameters: {
          'fields': 'id,displayName,shortName,description,periodType,style',
          'paging': 'false',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> dataSets = data['dataSets'] as List<dynamic>? ?? [];
        return dataSets
            .map((e) => DataSetModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw const ServerException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

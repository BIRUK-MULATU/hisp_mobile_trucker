import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../models/dataset_model.dart';
import '../models/dataset_section_model.dart';

abstract class CaptureRemoteDataSource {
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId);
  Future<List<DataSetModel>> getDataSetsForOrgUnit(String orgUnitId);
  Future<List<DataSetSectionModel>> getSections(String dataSetId);
}

class CaptureRemoteDataSourceImpl implements CaptureRemoteDataSource {
  final ApiClient _apiClient;

  CaptureRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId) async {
    try {
      final response = await _apiClient.get(
        '/organisationUnits/$parentId',
        queryParameters: {
          // One level only — the national hierarchy is ~38k units,
          // so deeper levels are fetched on expand. children~size
          // on each child says whether it can expand further.
          'fields': 'children[id,displayName,level,path,children~size]',
        },
      );

      if (response.statusCode != 200) throw const ServerException();

      final data = response.data as Map<String, dynamic>;
      final children = data['children'] as List<dynamic>? ?? [];
      return children.map((raw) {
        final c = raw as Map<String, dynamic>;
        return OrgUnitTreeNode(
          id: c['id'] as String? ?? '',
          name: c['displayName'] as String? ?? '',
          parentId: parentId,
          level: c['level'] as int? ?? 0,
          path: c['path'] as String?,
          childCount: c['children'] as int? ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<DataSetModel>> getDataSetsForOrgUnit(String orgUnitId) async {
    try {
      // Asked through the org unit's own association — the inverse
      // (/dataSets?filter=organisationUnits.id:eq:...) scans every
      // dataset↔orgUnit pair on the server and times out at scale.
      final response = await _apiClient.get(
        '/organisationUnits/$orgUnitId',
        queryParameters: {
          'fields': 'dataSets[id,displayName,shortName,description,'
              'periodType,style]',
        },
      );

      if (response.statusCode != 200) throw const ServerException();

      final data = response.data as Map<String, dynamic>;
      final dataSets = data['dataSets'] as List<dynamic>? ?? [];
      return dataSets
          .map((e) => DataSetModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<DataSetSectionModel>> getSections(String dataSetId) async {
    try {
      final response = await _apiClient.get(
        '/dataSets/$dataSetId',
        queryParameters: {
          'fields': 'sections[id,displayName,description,sortOrder]',
        },
      );

      if (response.statusCode != 200) throw const ServerException();

      final data = response.data as Map<String, dynamic>;
      final sections = data['sections'] as List<dynamic>? ?? [];
      return sections
          .map((e) => DataSetSectionModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

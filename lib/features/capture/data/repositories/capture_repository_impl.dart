import '../../domain/entities/dataset_entity.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../../domain/repositories/capture_repository.dart';
import '../datasources/capture_remote_datasource.dart';

class CaptureRepositoryImpl implements CaptureRepository {
  final CaptureRemoteDataSource _remoteDataSource;

  CaptureRepositoryImpl({required CaptureRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId) {
    return _remoteDataSource.getOrgUnitChildren(parentId);
  }

  @override
  Future<List<DataSetEntity>> getDataSetsForOrgUnit(String orgUnitId) {
    return _remoteDataSource.getDataSetsForOrgUnit(orgUnitId);
  }

  @override
  Future<List<DataSetSectionEntity>> getSections(String dataSetId) {
    return _remoteDataSource.getSections(dataSetId);
  }
}

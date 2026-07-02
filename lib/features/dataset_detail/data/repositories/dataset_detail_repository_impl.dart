import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/data_record_entity.dart';
import '../../domain/repositories/dataset_detail_repository.dart';
import '../datasources/dataset_detail_remote_datasource.dart';

class DatasetDetailRepositoryImpl implements DatasetDetailRepository {
  final DatasetDetailRemoteDataSource _remoteDataSource;

  DatasetDetailRepositoryImpl({
    required DatasetDetailRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<DataRecordEntity>> getRecords({
    required String dataSetId,
    required String orgUnitId,
  }) async {
    try {
      return await _remoteDataSource.getRecords(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<DataRecordEntity> createRecord({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  }) async {
    try {
      return await _remoteDataSource.createRecord(
        dataSetId: dataSetId,
        periodId: periodId,
        orgUnitId: orgUnitId,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteRecord(String recordId) async {}

  @override
  Future<DataRecordEntity> updateRecord(DataRecordEntity record) async {
    throw UnimplementedError();
  }
}

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/data_record_entity.dart';
import '../../domain/repositories/dataset_detail_repository.dart';
import '../datasources/dataset_detail_local_datasource.dart';
import '../datasources/dataset_detail_remote_datasource.dart';
import '../models/data_record_model.dart';

class DatasetDetailRepositoryImpl implements DatasetDetailRepository {
  final DatasetDetailRemoteDataSource _remoteDataSource;
  final DatasetDetailLocalDataSource _localDataSource;

  DatasetDetailRepositoryImpl({
    required DatasetDetailRemoteDataSource remoteDataSource,
    DatasetDetailLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource ??
            const UnimplementedDatasetDetailLocalDataSource();

  @override
  Future<List<DataRecordEntity>> getRecords({
    required String dataSetId,
    required String orgUnitId,
  }) async {
    try {
      final records = await _remoteDataSource.getRecords(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
      );
      await _localDataSource.cacheRecords(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        records: records,
      );
      return records;
    } on AppException catch (e) {
      // Offline/unreachable — serve cached records if any.
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      final cached = await _localDataSource.getCachedRecords(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
      );
      if (cached.isEmpty) rethrow;
      return cached;
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
    } on AppException catch (e) {
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      // Offline — queue the record locally; the SyncManager uploads
      // it later. Until offline storage exists the queue throws and
      // the original network error surfaces as before.
      final pending = DataRecordModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        dataSetId: dataSetId,
        periodId: periodId,
        orgUnitId: orgUnitId,
        isSynced: false,
      );
      try {
        await _localDataSource.queuePendingRecord(pending);
      } on CacheException {
        throw e;
      }
      return pending;
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

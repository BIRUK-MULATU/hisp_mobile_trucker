import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  // Local cache of datasets with sync status
  final Map<String, SyncStatus> _syncStatusCache = {};

  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<DataSetEntity>> getDataSets() async {
    try {
      final models = await _remoteDataSource.getDataSets();
      // Apply cached sync status
      return models.map((m) {
        final status = _syncStatusCache[m.id] ?? SyncStatus.unsynced;
        return m.copyWith(syncStatus: status);
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> syncDataSet(String dataSetId) async {
    // Mark as synced in local cache
    _syncStatusCache[dataSetId] = SyncStatus.synced;
  }

  @override
  Future<void> syncAll() async {
    // Will be implemented with full offline sync logic
  }
}

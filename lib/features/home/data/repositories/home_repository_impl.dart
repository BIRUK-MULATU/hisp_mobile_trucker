import '../../../../core/errors/exceptions.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/dataset_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;
  final SyncManager _syncManager;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    HomeLocalDataSource? localDataSource,
    SyncManager? syncManager,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource =
            localDataSource ?? const UnimplementedHomeLocalDataSource(),
        _syncManager = syncManager ?? const NoopSyncManager();

  @override
  Future<List<DataSetEntity>> getDataSets() async {
    List<DataSetModel> models;
    try {
      models = await _remoteDataSource.getDataSets();
      await _localDataSource.cacheDataSets(models);
    } on AppException catch (e) {
      // Offline/unreachable — serve the last cached list if any.
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      models = await _localDataSource.getCachedDataSets();
      if (models.isEmpty) rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }

    // Derive sync status from the local store: a dataset is unsynced
    // exactly when it has queued offline writes awaiting upload.
    final result = <DataSetEntity>[];
    for (final m in models) {
      final pending = await _localDataSource.hasPendingChanges(m.id);
      result.add(m.copyWith(
        syncStatus: pending ? SyncStatus.unsynced : SyncStatus.synced,
      ));
    }
    return result;
  }

  @override
  Future<void> syncDataSet(String dataSetId) async {
    await _syncManager.pushPending();
  }

  @override
  Future<void> syncAll() async {
    await _syncManager.pushPending();
    await _syncManager.pullLatest();
  }
}

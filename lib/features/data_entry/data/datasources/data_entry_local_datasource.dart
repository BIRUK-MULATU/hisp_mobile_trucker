import '../../../../core/errors/exceptions.dart';
import '../models/data_element_model.dart';

/// Local (SQLite) store for the data entry feature — implemented by
/// the backend team. See [HomeLocalDataSource] for the shared
/// conventions.
abstract class DataEntryLocalDataSource {
  /// Cached form metadata (data elements + category option combos)
  /// for a dataset.
  Future<List<DataElementModel>> getCachedDataElements(String dataSetId);

  Future<void> cacheDataElements(
    String dataSetId,
    List<DataElementModel> elements,
  );

  /// Cached values for one dataset/org unit/period, including values
  /// queued while offline (queued values win over cached server ones).
  Future<List<DataValueModel>> getCachedDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  Future<void> cacheDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    required List<DataValueModel> values,
  });

  /// Queues values entered while offline for the [SyncManager] to
  /// upload. Throws [CacheException] while offline storage is
  /// unavailable.
  Future<void> queuePendingDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    required List<DataValueModel> values,
  });

  /// Queues a "complete dataset" registration made while offline.
  /// Throws [CacheException] while offline storage is unavailable.
  Future<void> queuePendingCompletion({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });
}

/// Keeps the app fully remote until the SQLite implementation exists.
class UnimplementedDataEntryLocalDataSource
    implements DataEntryLocalDataSource {
  const UnimplementedDataEntryLocalDataSource();

  @override
  Future<List<DataElementModel>> getCachedDataElements(
          String dataSetId) async =>
      [];

  @override
  Future<void> cacheDataElements(
    String dataSetId,
    List<DataElementModel> elements,
  ) async {}

  @override
  Future<List<DataValueModel>> getCachedDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async =>
      [];

  @override
  Future<void> cacheDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    required List<DataValueModel> values,
  }) async {}

  @override
  Future<void> queuePendingDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    required List<DataValueModel> values,
  }) async =>
      throw const CacheException(
          message: 'Offline storage is not available yet.');

  @override
  Future<void> queuePendingCompletion({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async =>
      throw const CacheException(
          message: 'Offline storage is not available yet.');
}

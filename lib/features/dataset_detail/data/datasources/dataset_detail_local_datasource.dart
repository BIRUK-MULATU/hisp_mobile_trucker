import '../../../../core/errors/exceptions.dart';
import '../models/data_record_model.dart';

/// Local (SQLite) store for dataset records — implemented by the
/// backend team. See [HomeLocalDataSource] for the shared conventions.
abstract class DatasetDetailLocalDataSource {
  /// Records cached for this dataset/org unit, including any records
  /// queued while offline (those must have `isSynced == false`).
  Future<List<DataRecordModel>> getCachedRecords({
    required String dataSetId,
    required String orgUnitId,
  });

  /// Replaces the cached records for this dataset/org unit. Queued
  /// (unsynced) records must survive this call.
  Future<void> cacheRecords({
    required String dataSetId,
    required String orgUnitId,
    required List<DataRecordModel> records,
  });

  /// Queues a record created while offline. It must appear in
  /// [getCachedRecords] and be uploaded by the [SyncManager].
  /// Throws [CacheException] while offline storage is unavailable.
  Future<void> queuePendingRecord(DataRecordModel record);
}

/// Keeps the app fully remote until the SQLite implementation exists.
class UnimplementedDatasetDetailLocalDataSource
    implements DatasetDetailLocalDataSource {
  const UnimplementedDatasetDetailLocalDataSource();

  @override
  Future<List<DataRecordModel>> getCachedRecords({
    required String dataSetId,
    required String orgUnitId,
  }) async =>
      [];

  @override
  Future<void> cacheRecords({
    required String dataSetId,
    required String orgUnitId,
    required List<DataRecordModel> records,
  }) async {}

  @override
  Future<void> queuePendingRecord(DataRecordModel record) async =>
      throw const CacheException(
          message: 'Offline storage is not available yet.');
}

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/data_element_entity.dart';
import '../../domain/repositories/data_entry_repository.dart';
import '../datasources/data_entry_local_datasource.dart';
import '../datasources/data_entry_remote_datasource.dart';
import '../models/data_element_model.dart';

class DataEntryRepositoryImpl implements DataEntryRepository {
  final DataEntryRemoteDataSource _remoteDataSource;
  final DataEntryLocalDataSource _localDataSource;

  DataEntryRepositoryImpl({
    required DataEntryRemoteDataSource remoteDataSource,
    DataEntryLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource =
            localDataSource ?? const UnimplementedDataEntryLocalDataSource();

  // Data elements/category combos are static metadata for a dataset —
  // safe to cache for the lifetime of this repository instance so the
  // add-record prefetch and the form load don't hit the network twice.
  final Map<String, List<DataElementEntity>> _dataElementsCache = {};

  @override
  Future<List<DataElementEntity>> getDataElements({
    required String dataSetId,
    String? sectionId,
  }) async {
    // A section is a different form than the whole dataset — cache
    // (memory and local) under a key that separates the two.
    final cacheKey = sectionId == null ? dataSetId : '$dataSetId#$sectionId';
    final cached = _dataElementsCache[cacheKey];
    if (cached != null) return cached;

    try {
      final elements = await _remoteDataSource.getDataElements(
          dataSetId: dataSetId, sectionId: sectionId);
      await _localDataSource.cacheDataElements(cacheKey, elements);
      _dataElementsCache[cacheKey] = elements;
      return elements;
    } on AppException catch (e) {
      // Offline/unreachable — serve cached form metadata if any.
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      final local = await _localDataSource.getCachedDataElements(cacheKey);
      if (local.isEmpty) rethrow;
      _dataElementsCache[cacheKey] = local;
      return local;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      final values = await _remoteDataSource.getDataValues(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
      await _localDataSource.cacheDataValues(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
        values: values,
      );
      return values;
    } catch (e) {
      // Same contract as before (never throws) — but offline the
      // cached values come back instead of an empty form.
      return _localDataSource.getCachedDataValues(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
    }
  }

  @override
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    final models = dataValues
        .map((v) => DataValueModel(
              dataElementId: v.dataElementId,
              categoryOptionComboId: v.categoryOptionComboId,
              orgUnitId: v.orgUnitId,
              period: v.period,
              value: v.value,
            ))
        .toList();

    try {
      await _remoteDataSource.saveDataValues(
        dataValues: models,
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
      await _localDataSource.cacheDataValues(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
        values: models,
      );
    } on AppException catch (e) {
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      // Offline — queue the values locally; the SyncManager uploads
      // them later and the save reports success to the user. Until
      // offline storage exists the queue throws and the original
      // network error surfaces as before.
      try {
        await _localDataSource.queuePendingDataValues(
          dataSetId: dataSetId,
          orgUnitId: orgUnitId,
          period: period,
          values: models,
        );
      } on CacheException {
        throw e;
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      await _remoteDataSource.completeDataSet(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
    } on AppException catch (e) {
      if (e is! NetworkException && e is! TimeoutException) rethrow;
      // Offline — queue the completion for the SyncManager.
      try {
        await _localDataSource.queuePendingCompletion(
          dataSetId: dataSetId,
          orgUnitId: orgUnitId,
          period: period,
        );
      } on CacheException {
        throw e;
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}

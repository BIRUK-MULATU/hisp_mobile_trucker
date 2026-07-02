import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/data_element_entity.dart';
import '../../domain/repositories/data_entry_repository.dart';
import '../datasources/data_entry_remote_datasource.dart';
import '../models/data_element_model.dart';

class DataEntryRepositoryImpl implements DataEntryRepository {
  final DataEntryRemoteDataSource _remoteDataSource;

  DataEntryRepositoryImpl(
      {required DataEntryRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  // Data elements/category combos are static metadata for a dataset —
  // safe to cache for the lifetime of this repository instance so the
  // add-record prefetch and the form load don't hit the network twice.
  final Map<String, List<DataElementEntity>> _dataElementsCache = {};

  @override
  Future<List<DataElementEntity>> getDataElements({
    required String dataSetId,
  }) async {
    final cached = _dataElementsCache[dataSetId];
    if (cached != null) return cached;

    try {
      final elements = await _remoteDataSource.getDataElements(
          dataSetId: dataSetId);
      _dataElementsCache[dataSetId] = elements;
      return elements;
    } on AppException {
      rethrow;
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
      return await _remoteDataSource.getDataValues(
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    try {
      final models = dataValues
          .map((v) => DataValueModel(
                dataElementId: v.dataElementId,
                categoryOptionComboId: v.categoryOptionComboId,
                orgUnitId: v.orgUnitId,
                period: v.period,
                value: v.value,
              ))
          .toList();

      await _remoteDataSource.saveDataValues(
        dataValues: models,
        dataSetId: dataSetId,
        orgUnitId: orgUnitId,
        period: period,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    // TODO: implement complete dataset
  }
}

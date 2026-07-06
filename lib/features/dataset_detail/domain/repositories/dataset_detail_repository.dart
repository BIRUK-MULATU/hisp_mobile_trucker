import '../entities/data_record_entity.dart';

abstract class DatasetDetailRepository {
  Future<List<DataRecordEntity>> getRecords({
    required String dataSetId,
    required String orgUnitId,
  });

  Future<DataRecordEntity> createRecord({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  });
}

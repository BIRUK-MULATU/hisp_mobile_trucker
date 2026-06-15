import '../entities/data_record_entity.dart';

abstract class DatasetDetailRepository {
  Future<List<DataRecordEntity>> getRecords({
    required String dataSetId,
  });

  Future<DataRecordEntity> createRecord({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  });

  Future<void> deleteRecord(String recordId);

  Future<DataRecordEntity> updateRecord(DataRecordEntity record);
}

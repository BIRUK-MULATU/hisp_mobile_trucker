import '../entities/data_record_entity.dart';
import '../repositories/dataset_detail_repository.dart';

class GetRecordsUseCase {
  final DatasetDetailRepository _repository;
  const GetRecordsUseCase(this._repository);

  Future<List<DataRecordEntity>> call({
    required String dataSetId,
    required String orgUnitId,
  }) async {
    return await _repository.getRecords(
      dataSetId: dataSetId,
      orgUnitId: orgUnitId,
    );
  }
}

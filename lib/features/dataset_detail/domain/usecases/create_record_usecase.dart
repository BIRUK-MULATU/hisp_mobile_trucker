import '../entities/data_record_entity.dart';
import '../repositories/dataset_detail_repository.dart';

class CreateRecordUseCase {
  final DatasetDetailRepository _repository;
  const CreateRecordUseCase(this._repository);

  Future<DataRecordEntity> call({
    required String dataSetId,
    required String periodId,
    required String orgUnitId,
  }) async {
    return await _repository.createRecord(
      dataSetId: dataSetId,
      periodId: periodId,
      orgUnitId: orgUnitId,
    );
  }
}

import '../entities/dataset_entity.dart';
import '../repositories/capture_repository.dart';

class GetOrgUnitDataSetsUseCase {
  final CaptureRepository _repository;

  GetOrgUnitDataSetsUseCase(this._repository);

  Future<List<DataSetEntity>> call({required String orgUnitId}) {
    return _repository.getDataSetsForOrgUnit(orgUnitId);
  }
}

import '../repositories/home_repository.dart';

class SyncDataSetUseCase {
  final HomeRepository _repository;
  const SyncDataSetUseCase(this._repository);

  Future<void> call({String? dataSetId}) async {
    if (dataSetId != null) {
      await _repository.syncDataSet(dataSetId);
    } else {
      await _repository.syncAll();
    }
  }
}

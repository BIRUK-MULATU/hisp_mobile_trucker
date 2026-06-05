import '../entities/dataset_entity.dart';
import '../repositories/home_repository.dart';

class GetDataSetsUseCase {
  final HomeRepository _repository;
  const GetDataSetsUseCase(this._repository);

  Future<List<DataSetEntity>> call() async {
    return await _repository.getDataSets();
  }
}

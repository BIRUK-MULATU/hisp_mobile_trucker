import '../entities/data_element_entity.dart';
import '../repositories/data_entry_repository.dart';

class GetDataElementsUseCase {
  final DataEntryRepository _repository;
  const GetDataElementsUseCase(this._repository);

  Future<List<DataElementEntity>> call({
    required String dataSetId,
  }) async {
    return await _repository.getDataElements(dataSetId: dataSetId);
  }
}

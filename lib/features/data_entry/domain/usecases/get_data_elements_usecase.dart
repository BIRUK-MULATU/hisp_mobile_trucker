import '../entities/data_element_entity.dart';
import '../repositories/data_entry_repository.dart';

class GetDataElementsUseCase {
  final DataEntryRepository _repository;
  const GetDataElementsUseCase(this._repository);

  Future<List<DataElementEntity>> call({
    required String dataSetId,
    String? sectionId,
  }) async {
    return await _repository.getDataElements(
        dataSetId: dataSetId, sectionId: sectionId);
  }
}

import '../entities/dataset_section_entity.dart';
import '../repositories/capture_repository.dart';

class GetDataSetSectionsUseCase {
  final CaptureRepository _repository;

  GetDataSetSectionsUseCase(this._repository);

  Future<List<DataSetSectionEntity>> call({required String dataSetId}) {
    return _repository.getSections(dataSetId);
  }
}

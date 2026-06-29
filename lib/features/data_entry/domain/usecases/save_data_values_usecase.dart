import '../entities/data_element_entity.dart';
import '../repositories/data_entry_repository.dart';

class SaveDataValuesUseCase {
  final DataEntryRepository _repository;
  const SaveDataValuesUseCase(this._repository);

  Future<void> call({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    // Only save modified values
    final modified =
        dataValues.where((v) => v.isModified).toList();
    if (modified.isEmpty) return;

    await _repository.saveDataValues(
      dataValues: modified,
      dataSetId: dataSetId,
      orgUnitId: orgUnitId,
      period: period,
    );
  }
}

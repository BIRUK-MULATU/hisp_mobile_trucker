import '../entities/data_element_entity.dart';

abstract class DataEntryRepository {
  /// Fetch data elements and category combos for a dataset —
  /// restricted to one section when [sectionId] is given.
  Future<List<DataElementEntity>> getDataElements({
    required String dataSetId,
    String? sectionId,
  });

  /// Fetch existing data values for editing
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  /// Save all data values to DHIS2
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  /// Mark dataset as complete
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  /// Whether this form instance is currently marked complete —
  /// checked on form open so the save flow can offer reopening.
  Future<bool> isCompleted({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });

  /// Reopen a completed dataset: mark it incomplete locally and push
  /// the un-completion to the server when reachable.
  Future<void> uncompleteDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  });
}

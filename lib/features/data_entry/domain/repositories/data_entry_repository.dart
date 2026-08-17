import '../../../../core/data/validation_service.dart';
import '../entities/data_element_entity.dart';

abstract class DataEntryRepository {
  /// Fetch data elements and category combos for a dataset —
  /// restricted to one section when [sectionId] is given.
  Future<List<DataElementEntity>> getDataElements({
    required String dataSetId,
    String? sectionId,
  });

  /// Fetch existing data values for editing. [attributeOptionComboUid]
  /// scopes the form to one category-combo cell (e.g. Disease
  /// Registration's Department × Outcome) — null uses the data set's
  /// default combo, the only kind Routine data sets have.
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });

  /// Save all data values to DHIS2
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });

  /// Run the data set's validation rules against this form's local
  /// values. Purely informative — violations warn, they never block
  /// completing (same contract as the DHIS2 web/Android apps).
  Future<List<ValidationViolation>> validateDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });

  /// Same rule check as [validateDataSet], but evaluated against
  /// values already held in memory (e.g. the data-entry Bloc's
  /// current state) instead of the local database — lets validation
  /// run live as the user types, before anything has been saved.
  Future<List<ValidationViolation>> validateLiveValues({
    required String dataSetId,
    required List<DataValueEntity> dataValues,
  });

  /// Mark dataset as complete
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });

  /// Whether this form instance is currently marked complete —
  /// checked on form open so the save flow can offer reopening.
  Future<bool> isCompleted({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });

  /// Reopen a completed dataset: mark it incomplete locally and push
  /// the un-completion to the server when reachable.
  Future<void> uncompleteDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  });
}

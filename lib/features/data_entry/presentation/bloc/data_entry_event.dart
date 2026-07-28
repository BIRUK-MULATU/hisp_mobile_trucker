part of 'data_entry_bloc.dart';

abstract class DataEntryEvent {
  const DataEntryEvent();
}

class DataEntryLoad extends DataEntryEvent {
  final String dataSetId;
  final String orgUnitId;
  final String period;

  /// Restricts the form to one dataset section; null = whole dataset.
  final String? sectionId;

  /// Scopes the form to one category-combo cell of the data set's OWN
  /// category combination (e.g. Disease Registration's Department ×
  /// Outcome). Null uses the data set's default combo.
  final String? attributeOptionComboUid;

  const DataEntryLoad({
    required this.dataSetId,
    required this.orgUnitId,
    required this.period,
    this.sectionId,
    this.attributeOptionComboUid,
  });
}

class DataEntryValueChanged extends DataEntryEvent {
  final String dataElementId;
  final String categoryOptionComboId;
  final String value;

  const DataEntryValueChanged({
    required this.dataElementId,
    required this.categoryOptionComboId,
    required this.value,
  });
}

class DataEntrySave extends DataEntryEvent {
  const DataEntrySave();
}

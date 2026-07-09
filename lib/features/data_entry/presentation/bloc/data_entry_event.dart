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

  const DataEntryLoad({
    required this.dataSetId,
    required this.orgUnitId,
    required this.period,
    this.sectionId,
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

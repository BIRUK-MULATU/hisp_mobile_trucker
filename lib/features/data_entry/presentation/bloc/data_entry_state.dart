part of 'data_entry_bloc.dart';

abstract class DataEntryState {
  const DataEntryState();
}

class DataEntryInitial extends DataEntryState {
  const DataEntryInitial();
}

class DataEntryLoading extends DataEntryState {
  const DataEntryLoading();
}

class DataEntryLoaded extends DataEntryState {
  final List<DataElementEntity> dataElements;
  final Map<String, DataValueEntity> dataValues;
  final bool hasChanges;
  final bool isSaving;

  const DataEntryLoaded({
    required this.dataElements,
    required this.dataValues,
    this.hasChanges = false,
    this.isSaving = false,
  });

  DataEntryLoaded copyWith({
    List<DataElementEntity>? dataElements,
    Map<String, DataValueEntity>? dataValues,
    bool? hasChanges,
    bool? isSaving,
  }) {
    return DataEntryLoaded(
      dataElements: dataElements ?? this.dataElements,
      dataValues: dataValues ?? this.dataValues,
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class DataEntryError extends DataEntryState {
  final String message;
  const DataEntryError(this.message);
}

class DataEntrySaved extends DataEntryState {
  const DataEntrySaved();
}

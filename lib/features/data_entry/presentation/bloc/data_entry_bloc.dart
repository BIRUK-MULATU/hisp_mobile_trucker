import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/value_type_validator.dart';
import '../../domain/entities/data_element_entity.dart';
import '../../domain/repositories/data_entry_repository.dart';
import '../../domain/usecases/get_data_elements_usecase.dart';
import '../../domain/usecases/save_data_values_usecase.dart';

part 'data_entry_event.dart';
part 'data_entry_state.dart';

/// "Element — problem" for every user-EDITED value in the loaded form
/// that violates its element's valueType. Values that arrived from the
/// server unedited are not judged here.
List<String> invalidEditedValues(DataEntryLoaded state) {
  final typeOf = {for (final e in state.dataElements) e.id: e};
  final problems = <String>[];
  for (final v in state.dataValues.values) {
    if (!v.isModified) continue;
    final element = typeOf[v.dataElementId];
    if (element == null) continue; // not part of the loaded form
    final why = validateDataValue(
      element.valueType,
      v.value,
      optionCodes: element.options.isEmpty
          ? null
          : {for (final o in element.options) o.code},
    );
    if (why != null) problems.add('${element.displayName}: $why');
  }
  return problems;
}

class DataEntryBloc extends Bloc<DataEntryEvent, DataEntryState> {
  final GetDataElementsUseCase _getDataElementsUseCase;
  final SaveDataValuesUseCase _saveDataValuesUseCase;

  // Exposed so DataEntryPage can call completeDataSet
  final DataEntryRepository repository;

  String _dataSetId = '';
  String _orgUnitId = '';
  String _period = '';

  DataEntryBloc({
    required GetDataElementsUseCase getDataElementsUseCase,
    required SaveDataValuesUseCase saveDataValuesUseCase,
    required this.repository,
  })  : _getDataElementsUseCase = getDataElementsUseCase,
        _saveDataValuesUseCase = saveDataValuesUseCase,
        super(const DataEntryInitial()) {
    on<DataEntryLoad>(_onLoad);
    on<DataEntryValueChanged>(_onValueChanged);
    on<DataEntrySave>(_onSave);
  }

  Future<void> _onLoad(
    DataEntryLoad event,
    Emitter<DataEntryState> emit,
  ) async {
    _dataSetId = event.dataSetId;
    _orgUnitId = event.orgUnitId;
    _period = event.period;

    emit(const DataEntryLoading());

    try {
      final results = await Future.wait([
        _getDataElementsUseCase.call(
            dataSetId: event.dataSetId, sectionId: event.sectionId),
        repository.getDataValues(
          dataSetId: event.dataSetId,
          orgUnitId: event.orgUnitId,
          period: event.period,
        ),
      ]);

      final dataElements = results[0] as List<DataElementEntity>;
      final existingValues = results[1] as List<DataValueEntity>;

      final valueMap = <String, DataValueEntity>{};
      for (final v in existingValues) {
        valueMap[v.key] = v;
      }

      emit(DataEntryLoaded(
        dataElements: dataElements,
        dataValues: valueMap,
      ));
    } catch (e) {
      emit(DataEntryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onValueChanged(
    DataEntryValueChanged event,
    Emitter<DataEntryState> emit,
  ) {
    if (state is DataEntryLoaded) {
      final current = state as DataEntryLoaded;
      final key = '${event.dataElementId}_${event.categoryOptionComboId}';

      final updatedValues =
          Map<String, DataValueEntity>.from(current.dataValues);

      final existing = updatedValues[key];
      if (existing != null) {
        existing.value = event.value;
        existing.isModified = true;
        // Editing a rejected cell resolves it: saving re-queues the
        // value as pending, so the stale server error no longer applies.
        existing.syncError = null;
      } else {
        updatedValues[key] = DataValueEntity(
          dataElementId: event.dataElementId,
          categoryOptionComboId: event.categoryOptionComboId,
          orgUnitId: _orgUnitId,
          period: _period,
          value: event.value,
          isModified: true,
        );
      }

      emit(current.copyWith(
        dataValues: updatedValues,
        hasChanges: true,
      ));
    }
  }

  Future<void> _onSave(
    DataEntrySave event,
    Emitter<DataEntryState> emit,
  ) async {
    if (state is DataEntryLoaded) {
      final current = state as DataEntryLoaded;

      // Same value-type gate as the page's save button — no path may
      // queue an invalid value.
      final invalid = invalidEditedValues(current);
      if (invalid.isNotEmpty) {
        emit(current.copyWith(isSaving: false));
        emit(DataEntryError(
            'Invalid values not saved: ${invalid.join('; ')}'));
        return;
      }

      emit(current.copyWith(isSaving: true));

      // Only the loaded form's values — when a single section is
      // open, the map also holds the other sections' existing
      // values, which must not be re-posted on every save.
      final formElementIds = current.dataElements.map((e) => e.id).toSet();
      final valuesToSave = current.dataValues.values
          .where((v) => formElementIds.contains(v.dataElementId))
          .toList();

      try {
        await _saveDataValuesUseCase.call(
          dataValues: valuesToSave,
          dataSetId: _dataSetId,
          orgUnitId: _orgUnitId,
          period: _period,
        );
        emit(const DataEntrySaved());
      } catch (e) {
        emit(current.copyWith(isSaving: false));
        emit(DataEntryError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}

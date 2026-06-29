import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/data_element_entity.dart';
import '../../domain/usecases/get_data_elements_usecase.dart';
import '../../domain/usecases/save_data_values_usecase.dart';
import '../../domain/repositories/data_entry_repository.dart';

part 'data_entry_event.dart';
part 'data_entry_state.dart';

class DataEntryBloc extends Bloc<DataEntryEvent, DataEntryState> {
  final GetDataElementsUseCase _getDataElementsUseCase;
  final SaveDataValuesUseCase _saveDataValuesUseCase;
  final DataEntryRepository _repository;

  String _dataSetId = '';
  String _orgUnitId = '';
  String _period = '';

  DataEntryBloc({
    required GetDataElementsUseCase getDataElementsUseCase,
    required SaveDataValuesUseCase saveDataValuesUseCase,
    required DataEntryRepository repository,
  })  : _getDataElementsUseCase = getDataElementsUseCase,
        _saveDataValuesUseCase = saveDataValuesUseCase,
        _repository = repository,
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
      // Load data elements and existing values in parallel
      final results = await Future.wait([
        _getDataElementsUseCase.call(dataSetId: event.dataSetId),
        _repository.getDataValues(
          dataSetId: event.dataSetId,
          orgUnitId: event.orgUnitId,
          period: event.period,
        ),
      ]);

      final dataElements =
          results[0] as List<DataElementEntity>;
      final existingValues =
          results[1] as List<DataValueEntity>;

      // Build value map from existing values
      final valueMap = <String, DataValueEntity>{};
      for (final v in existingValues) {
        valueMap[v.key] = v;
      }

      emit(DataEntryLoaded(
        dataElements: dataElements,
        dataValues: valueMap,
      ));
    } catch (e) {
      emit(DataEntryError(
          e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onValueChanged(
    DataEntryValueChanged event,
    Emitter<DataEntryState> emit,
  ) {
    if (state is DataEntryLoaded) {
      final current = state as DataEntryLoaded;
      final key =
          '${event.dataElementId}_${event.categoryOptionComboId}';

      final updatedValues =
          Map<String, DataValueEntity>.from(current.dataValues);

      final existing = updatedValues[key];
      if (existing != null) {
        existing.value = event.value;
        existing.isModified = true;
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
      emit(current.copyWith(isSaving: true));

      try {
        await _saveDataValuesUseCase.call(
          dataValues: current.dataValues.values.toList(),
          dataSetId: _dataSetId,
          orgUnitId: _orgUnitId,
          period: _period,
        );
        emit(const DataEntrySaved());
      } catch (e) {
        emit(current.copyWith(isSaving: false));
        emit(DataEntryError(
            e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}

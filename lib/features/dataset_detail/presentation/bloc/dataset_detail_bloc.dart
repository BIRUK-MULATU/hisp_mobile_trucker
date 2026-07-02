import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/data_record_entity.dart';
import '../../domain/usecases/get_records_usecase.dart';
import '../../domain/usecases/create_record_usecase.dart';

part 'dataset_detail_event.dart';
part 'dataset_detail_state.dart';

class DatasetDetailBloc
    extends Bloc<DatasetDetailEvent, DatasetDetailState> {
  final GetRecordsUseCase _getRecordsUseCase;
  final CreateRecordUseCase _createRecordUseCase;

  DatasetDetailBloc({
    required GetRecordsUseCase getRecordsUseCase,
    required CreateRecordUseCase createRecordUseCase,
  })  : _getRecordsUseCase = getRecordsUseCase,
        _createRecordUseCase = createRecordUseCase,
        super(const DatasetDetailInitial()) {
    on<DatasetDetailLoad>(_onLoad);
    on<DatasetDetailRefresh>(_onRefresh);
    on<DatasetDetailCreateRecord>(_onCreateRecord);
  }

  Future<void> _onLoad(
    DatasetDetailLoad event,
    Emitter<DatasetDetailState> emit,
  ) async {
    emit(const DatasetDetailLoading());
    try {
      final records = await _getRecordsUseCase.call(
        dataSetId: event.dataSetId,
        orgUnitId: event.orgUnitId,
      );
      emit(DatasetDetailLoaded(records));
    } catch (e) {
      // Show empty state instead of error for new datasets
      emit(const DatasetDetailLoaded([]));
    }
  }

  Future<void> _onRefresh(
    DatasetDetailRefresh event,
    Emitter<DatasetDetailState> emit,
  ) async {
    try {
      final records = await _getRecordsUseCase.call(
        dataSetId: event.dataSetId,
        orgUnitId: event.orgUnitId,
      );
      emit(DatasetDetailLoaded(records));
    } catch (e) {
      emit(const DatasetDetailLoaded([]));
    }
  }

  Future<void> _onCreateRecord(
    DatasetDetailCreateRecord event,
    Emitter<DatasetDetailState> emit,
  ) async {
    try {
      final record = await _createRecordUseCase.call(
        dataSetId: event.dataSetId,
        periodId: event.periodId,
        orgUnitId: event.orgUnitId,
      );
      emit(DatasetDetailRecordCreated(record));
    } catch (e) {
      emit(DatasetDetailError(e.toString()));
    }
  }
}

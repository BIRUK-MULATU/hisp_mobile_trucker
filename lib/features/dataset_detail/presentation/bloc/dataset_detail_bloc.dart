import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
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
      // An empty dataset returns 200 with no records, so reaching
      // here always means a real failure — show it, with retry.
      emit(DatasetDetailError(_messageOf(e)));
    }
  }

  Future<void> _onRefresh(
    DatasetDetailRefresh event,
    Emitter<DatasetDetailState> emit,
  ) async {
    final previous = state;
    try {
      final records = await _getRecordsUseCase.call(
        dataSetId: event.dataSetId,
        orgUnitId: event.orgUnitId,
      );
      emit(DatasetDetailLoaded(records));
    } catch (e) {
      // Keep the records already on screen; only surface the error
      // when there is nothing to fall back to.
      if (previous is DatasetDetailLoaded && !previous.isEmpty) return;
      emit(DatasetDetailError(_messageOf(e)));
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
      emit(DatasetDetailError(_messageOf(e)));
    }
  }

  String _messageOf(Object e) => e is AppException
      ? e.message
      : e.toString().replaceAll('Exception: ', '');
}

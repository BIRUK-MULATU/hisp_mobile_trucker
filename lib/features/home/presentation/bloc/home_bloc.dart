import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/usecases/get_datasets_usecase.dart';
import '../../domain/usecases/sync_dataset_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDataSetsUseCase _getDataSetsUseCase;
  final SyncDataSetUseCase _syncDataSetUseCase;

  HomeBloc({
    required GetDataSetsUseCase getDataSetsUseCase,
    required SyncDataSetUseCase syncDataSetUseCase,
  })  : _getDataSetsUseCase = getDataSetsUseCase,
        _syncDataSetUseCase = syncDataSetUseCase,
        super(const HomeInitial()) {
    on<HomeLoadDataSets>(_onLoadDataSets);
    on<HomeRefresh>(_onRefresh);
    on<HomeSyncDataSet>(_onSyncDataSet);
    on<HomeSyncAll>(_onSyncAll);
  }

  Future<void> _onLoadDataSets(
    HomeLoadDataSets event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final dataSets = await _getDataSetsUseCase.call();
      emit(HomeLoaded(dataSets: dataSets));
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefresh(
    HomeRefresh event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final dataSets = await _getDataSetsUseCase.call();
      emit(HomeLoaded(dataSets: dataSets));
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSyncDataSet(
    HomeSyncDataSet event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(current.copyWith(isSyncing: true));
      try {
        await _syncDataSetUseCase.call(dataSetId: event.dataSetId);
        final dataSets = await _getDataSetsUseCase.call();
        emit(HomeLoaded(dataSets: dataSets));
      } catch (e) {
        emit(current.copyWith(isSyncing: false));
      }
    }
  }

  Future<void> _onSyncAll(
    HomeSyncAll event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(current.copyWith(isSyncing: true));
      try {
        await _syncDataSetUseCase.call();
        final dataSets = await _getDataSetsUseCase.call();
        emit(HomeLoaded(dataSets: dataSets));
      } catch (e) {
        emit(current.copyWith(isSyncing: false));
      }
    }
  }
}

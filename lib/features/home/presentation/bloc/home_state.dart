part of 'home_bloc.dart';

abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<DataSetEntity> dataSets;
  final bool isSyncing;

  const HomeLoaded({
    required this.dataSets,
    this.isSyncing = false,
  });

  HomeLoaded copyWith({
    List<DataSetEntity>? dataSets,
    bool? isSyncing,
  }) {
    return HomeLoaded(
      dataSets: dataSets ?? this.dataSets,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

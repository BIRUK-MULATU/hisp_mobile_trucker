part of 'home_bloc.dart';

abstract class HomeEvent {
  const HomeEvent();
}

class HomeLoadDataSets extends HomeEvent {
  const HomeLoadDataSets();
}

class HomeSyncDataSet extends HomeEvent {
  final String dataSetId;
  const HomeSyncDataSet(this.dataSetId);
}

class HomeSyncAll extends HomeEvent {
  const HomeSyncAll();
}

class HomeRefresh extends HomeEvent {
  const HomeRefresh();
}

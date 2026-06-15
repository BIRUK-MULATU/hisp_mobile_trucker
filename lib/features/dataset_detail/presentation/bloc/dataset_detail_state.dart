part of 'dataset_detail_bloc.dart';

abstract class DatasetDetailState {
  const DatasetDetailState();
}

class DatasetDetailInitial extends DatasetDetailState {
  const DatasetDetailInitial();
}

class DatasetDetailLoading extends DatasetDetailState {
  const DatasetDetailLoading();
}

class DatasetDetailLoaded extends DatasetDetailState {
  final List<DataRecordEntity> records;
  const DatasetDetailLoaded(this.records);

  bool get isEmpty => records.isEmpty;
}

class DatasetDetailError extends DatasetDetailState {
  final String message;
  const DatasetDetailError(this.message);
}

class DatasetDetailRecordCreated extends DatasetDetailState {
  final DataRecordEntity record;
  const DatasetDetailRecordCreated(this.record);
}

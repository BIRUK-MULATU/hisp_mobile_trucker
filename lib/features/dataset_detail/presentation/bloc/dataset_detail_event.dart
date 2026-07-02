part of 'dataset_detail_bloc.dart';

abstract class DatasetDetailEvent {
  const DatasetDetailEvent();
}

class DatasetDetailLoad extends DatasetDetailEvent {
  final String dataSetId;
  final String orgUnitId;
  const DatasetDetailLoad(this.dataSetId, this.orgUnitId);
}

class DatasetDetailRefresh extends DatasetDetailEvent {
  final String dataSetId;
  final String orgUnitId;
  const DatasetDetailRefresh(this.dataSetId, this.orgUnitId);
}

class DatasetDetailCreateRecord extends DatasetDetailEvent {
  final String dataSetId;
  final String periodId;
  final String orgUnitId;

  const DatasetDetailCreateRecord({
    required this.dataSetId,
    required this.periodId,
    required this.orgUnitId,
  });
}

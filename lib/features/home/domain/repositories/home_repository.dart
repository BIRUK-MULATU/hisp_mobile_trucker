import '../entities/dataset_entity.dart';

abstract class HomeRepository {
  Future<List<DataSetEntity>> getDataSets();
  Future<void> syncDataSet(String dataSetId);
  Future<void> syncAll();
}

import '../models/dataset_model.dart';

/// Local (SQLite) store for the home feature — implemented by the
/// backend team. Conventions shared by all local datasources:
///
///  * Read methods return an empty list when nothing is cached; they
///    never throw for "no data".
///  * `cache*` methods replace previously cached rows for the same key.
///  * Repositories call the remote API first and only fall back here
///    on [NetworkException]/[TimeoutException].
abstract class HomeLocalDataSource {
  /// Datasets stored by the last successful remote fetch.
  Future<List<DataSetModel>> getCachedDataSets();

  /// Replaces the cached dataset list.
  Future<void> cacheDataSets(List<DataSetModel> dataSets);

  /// True when this dataset has queued local writes (data values,
  /// records, or completions) not yet pushed to the server. Drives
  /// the red "unsync" badge on the home page.
  Future<bool> hasPendingChanges(String dataSetId);
}

/// Keeps the app fully remote until the SQLite implementation exists:
/// nothing is ever cached, so repositories always use the API result,
/// and nothing can be pending, so datasets show as synced.
class UnimplementedHomeLocalDataSource implements HomeLocalDataSource {
  const UnimplementedHomeLocalDataSource();

  @override
  Future<List<DataSetModel>> getCachedDataSets() async => [];

  @override
  Future<void> cacheDataSets(List<DataSetModel> dataSets) async {}

  @override
  Future<bool> hasPendingChanges(String dataSetId) async => false;
}

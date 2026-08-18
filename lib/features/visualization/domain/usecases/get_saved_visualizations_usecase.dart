import '../entities/chart_config.dart';
import '../repositories/local_visualization_repository.dart';

class GetSavedVisualizationsUseCase {
  final LocalVisualizationRepository _repository;

  GetSavedVisualizationsUseCase(this._repository);

  Future<List<ChartConfig>> call() => _repository.getSavedCharts();
}

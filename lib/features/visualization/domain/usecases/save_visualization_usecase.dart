import '../entities/chart_config.dart';
import '../repositories/local_visualization_repository.dart';

/// Creates a new saved visualization, or — when [config.id] matches
/// an existing one — overwrites it in place. That single rule is how
/// both "Save" (new chart) and "Save changes" (editing an existing
/// one) are the same call.
class SaveVisualizationUseCase {
  final LocalVisualizationRepository _repository;

  SaveVisualizationUseCase(this._repository);

  Future<void> call(ChartConfig config) => _repository.saveChart(config);
}

import '../entities/chart_config.dart';
import '../repositories/local_visualization_repository.dart';

/// Online-first, cache-fallback load for the chart VIEW screen — see
/// [LocalVisualizationRepository.loadChart].
class LoadVisualizationUseCase {
  final LocalVisualizationRepository _repository;

  LoadVisualizationUseCase(this._repository);

  Future<ChartLoadResult> call(
    ChartConfig config, {
    bool skipLiveAttempt = false,
  }) =>
      _repository.loadChart(config, skipLiveAttempt: skipLiveAttempt);
}

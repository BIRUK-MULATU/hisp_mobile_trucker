import '../repositories/local_visualization_repository.dart';

class DeleteVisualizationUseCase {
  final LocalVisualizationRepository _repository;

  DeleteVisualizationUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteChart(id);
}

import '../entities/org_unit_tree_node.dart';
import '../repositories/capture_repository.dart';

class GetOrgUnitChildrenUseCase {
  final CaptureRepository _repository;

  GetOrgUnitChildrenUseCase(this._repository);

  Future<List<OrgUnitTreeNode>> call({required String parentId}) {
    return _repository.getOrgUnitChildren(parentId);
  }
}

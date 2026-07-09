import '../entities/dataset_entity.dart';
import '../entities/dataset_section_entity.dart';
import '../entities/org_unit_tree_node.dart';

abstract class CaptureRepository {
  /// One level of children of [parentId] — the tree is loaded
  /// lazily per expand, never as a whole.
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId);

  /// Datasets assigned to [orgUnitId] (and readable by the user).
  Future<List<DataSetEntity>> getDataSetsForOrgUnit(String orgUnitId);

  /// Sections of a dataset, ordered by sortOrder. Empty when the
  /// dataset has no sections (form is captured as a whole).
  Future<List<DataSetSectionEntity>> getSections(String dataSetId);
}

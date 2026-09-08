import '../entities/dataset_entity.dart';
import '../entities/dataset_section_entity.dart';
import '../entities/expected_report_entity.dart';
import '../entities/org_unit_tree_node.dart';
import '../entities/report_instance_entity.dart';

abstract class CaptureRepository {
  /// One level of children of [parentId] — the tree is loaded
  /// lazily per expand, never as a whole.
  Future<List<OrgUnitTreeNode>> getOrgUnitChildren(String parentId);

  /// Datasets assigned to [orgUnitId] (and readable by the user) —
  /// Routine and Disease Registration together, one merged list.
  /// Each entity flags [DataSetEntity.isDiseaseRegistration] so the UI
  /// can style disease datasets differently within the same flow.
  Future<List<DataSetEntity>> getDataSetsForOrgUnit(String orgUnitId);

  /// Sections of a dataset, ordered by sortOrder. Empty when the
  /// dataset has no sections (form is captured as a whole).
  Future<List<DataSetSectionEntity>> getSections(String dataSetId);

  /// The named org units for [ids], sorted by name — flat leaf nodes
  /// for the filtered capture list (no children, no expanding).
  Future<List<OrgUnitTreeNode>> getOrgUnitsByIds(Set<String> ids);

  /// Every report the user has worked on locally — completed
  /// registrations plus incomplete (draft) forms — across ALL org
  /// units, newest first. Routine and Disease Registration together,
  /// same merge as [getDataSetsForOrgUnit].
  Future<List<ReportInstanceEntity>> getUserReports();

  /// Reports the user still OWES: every dataset assigned to one of
  /// their own facilities (capture roots + direct children), for every
  /// period still open for entry, that isn't already completed
  /// (locally or on the server). Sorted most-urgent first. Best-effort
  /// pulls the server's completion state first when online, so a
  /// report finished on the web doesn't linger here.
  Future<List<ExpectedReportEntity>> getExpectedReports();
}

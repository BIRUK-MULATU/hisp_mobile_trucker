class OrgUnitTreeNode {
  final String id;
  final String name;
  final String? parentId;
  final int level;
  final String? path;
  final List<OrgUnitTreeNode> children;
  bool isExpanded;
  bool isSelected;
  bool isAssigned;

  OrgUnitTreeNode({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    this.path,
    List<OrgUnitTreeNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
    this.isAssigned = false,
  }) : children = children ?? [];

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgUnitTreeNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

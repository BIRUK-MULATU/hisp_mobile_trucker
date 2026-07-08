class OrgUnitTreeNode {
  final String id;
  final String name;
  final String? parentId;
  final int level;
  final String? path;
  final List<OrgUnitTreeNode> children;

  /// Number of children on the server — children themselves are
  /// fetched lazily on expand (the hierarchy is ~38k units on a
  /// national instance), so this drives the expand arrow before
  /// [children] is populated.
  final int childCount;

  bool isExpanded;
  bool isSelected;
  bool isAssigned;
  bool childrenLoaded;
  bool isLoadingChildren;

  OrgUnitTreeNode({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    this.path,
    List<OrgUnitTreeNode>? children,
    this.childCount = 0,
    this.isExpanded = false,
    this.isSelected = false,
    this.isAssigned = false,
    this.childrenLoaded = false,
    this.isLoadingChildren = false,
  }) : children = children ?? [];

  bool get hasChildren => childCount > 0 || children.isNotEmpty;
  bool get isLeaf => !hasChildren;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgUnitTreeNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

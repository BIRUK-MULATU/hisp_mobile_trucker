import '../entities/org_unit_tree_node.dart';

class OrgUnitTreeService {
  OrgUnitTreeService._();

  static List<OrgUnitTreeNode> buildTree(
    List<Map<String, dynamic>> flatList,
    List<String> assignedIds,
  ) {
    final Map<String, OrgUnitTreeNode> nodeMap = {};

    for (final item in flatList) {
      final id = item['id'] as String? ?? '';
      final path = item['path'] as String? ?? '';
      final level = item['level'] as int? ?? _getLevelFromPath(path);
      final name = item['displayName'] as String? ??
          item['name'] as String? ?? '';

      nodeMap[id] = OrgUnitTreeNode(
        id: id,
        name: name,
        parentId: item['parent'] != null
            ? item['parent']['id'] as String?
            : null,
        level: level,
        path: path,
        children: [],
        isExpanded: assignedIds.contains(id) ||
            _hasAssignedDescendant(path, assignedIds, flatList),
        isSelected: assignedIds.contains(id),
        isAssigned: assignedIds.contains(id),
      );
    }

    final List<OrgUnitTreeNode> roots = [];

    for (final node in nodeMap.values) {
      final parentId = node.parentId;
      if (parentId == null || !nodeMap.containsKey(parentId)) {
        roots.add(node);
      } else {
        nodeMap[parentId]!.children.add(node);
      }
    }

    _sortTree(roots);
    return roots;
  }

  static void _sortTree(List<OrgUnitTreeNode> nodes) {
    nodes.sort((a, b) => a.name.compareTo(b.name));
    for (final node in nodes) {
      _sortTree(node.children);
    }
  }

  static int _getLevelFromPath(String path) {
    if (path.isEmpty) return 1;
    return path.split('/').where((s) => s.isNotEmpty).length;
  }

  static bool _hasAssignedDescendant(
    String path,
    List<String> assignedIds,
    List<Map<String, dynamic>> flatList,
  ) {
    if (path.isEmpty) return false;
    return flatList.any((item) {
      final itemPath = item['path'] as String? ?? '';
      final itemId = item['id'] as String? ?? '';
      return itemPath.startsWith('$path/') &&
          assignedIds.contains(itemId);
    });
  }
}

class FlatNode {
  final OrgUnitTreeNode node;
  final int depth;
  const FlatNode({required this.node, required this.depth});
}

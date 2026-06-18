import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../domain/entities/org_unit_tree_node.dart';
import '../domain/services/org_unit_tree_service.dart';

class OrgUnitSelectorPage extends StatefulWidget {
  final String? preSelectedId;

  const OrgUnitSelectorPage({
    super.key,
    this.preSelectedId,
  });

  @override
  State<OrgUnitSelectorPage> createState() =>
      _OrgUnitSelectorPageState();
}

class _OrgUnitSelectorPageState
    extends State<OrgUnitSelectorPage> {
  final _searchController = TextEditingController();
  final _secureStorage = SecureStorage();

  List<OrgUnitTreeNode> _tree = [];
  List<FlatNode> _flatNodes = [];
  List<FlatNode> _filteredNodes = [];
  String? _selectedId;
  String? _selectedName;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.preSelectedId;
    _loadOrgUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrgUnits() async {
    final orgUnits = await _secureStorage.getOrgUnits();
    final assignedIds =
        orgUnits.map((o) => o['id'] as String? ?? '').toList();

    if (assignedIds.length == 1) {
      _selectedId = assignedIds.first;
      _selectedName = orgUnits.first['displayName'] as String? ??
          orgUnits.first['name'] as String?;
    }

    _tree = OrgUnitTreeService.buildTree(orgUnits, assignedIds);
    _flatNodes = _buildFlatNodes(_tree);
    _filteredNodes = List.from(_flatNodes);

    if (mounted) setState(() => _isLoading = false);
  }

  List<FlatNode> _buildFlatNodes(
    List<OrgUnitTreeNode> nodes, {
    int depth = 0,
  }) {
    final result = <FlatNode>[];
    for (final node in nodes) {
      result.add(FlatNode(node: node, depth: depth));
      if (node.isExpanded) {
        result.addAll(
            _buildFlatNodes(node.children, depth: depth + 1));
      }
    }
    return result;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredNodes = List.from(_flatNodes);
      } else {
        _filteredNodes = _flatNodes
            .where((n) =>
                n.node.name.toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  void _toggleExpand(OrgUnitTreeNode node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
      _flatNodes = _buildFlatNodes(_tree);
      _filteredNodes = _searchQuery.isEmpty
          ? List.from(_flatNodes)
          : _flatNodes
              .where((n) =>
                  n.node.name.toLowerCase().contains(_searchQuery))
              .toList();
    });
  }

  void _selectNode(OrgUnitTreeNode node) {
    setState(() {
      _selectedId = node.id;
      _selectedName = node.name;
    });
  }

  void _clearAll() {
    setState(() {
      _selectedId = null;
      _selectedName = null;
    });
  }

  void _done() {
    if (_selectedId != null) {
      Navigator.pop(context, {
        'id': _selectedId,
        'name': _selectedName,
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ──────────────────────────
            _SearchBar(
              controller: _searchController,
              onChanged: _onSearch,
            ),

            const Divider(height: 1),

            // ── Tree List ───────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _filteredNodes.isEmpty
                      ? _EmptySearchResult(query: _searchQuery)
                      : ListView.builder(
                          itemCount: _filteredNodes.length,
                          itemBuilder: (context, index) {
                            final flatNode = _filteredNodes[index];
                            return _OrgUnitTreeTile(
                              node: flatNode.node,
                              depth: flatNode.depth,
                              isSelected:
                                  flatNode.node.id == _selectedId,
                              onExpand: flatNode.node.hasChildren
                                  ? () =>
                                      _toggleExpand(flatNode.node)
                                  : null,
                              onSelect: () =>
                                  _selectNode(flatNode.node),
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // ── Bottom Actions ──────────────────────
            _BottomActions(
              onClearAll: _clearAll,
              onDone: _done,
              hasSelection: _selectedId != null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle:
                    TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: AppDimensions.iconLG,
          ),
        ],
      ),
    );
  }
}

// ── Tree Tile ──────────────────────────────────────────────────
class _OrgUnitTreeTile extends StatelessWidget {
  final OrgUnitTreeNode node;
  final int depth;
  final bool isSelected;
  final VoidCallback? onExpand;
  final VoidCallback? onSelect;

  const _OrgUnitTreeTile({
    required this.node,
    required this.depth,
    required this.isSelected,
    this.onExpand,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: node.isLeaf ? onSelect : onExpand,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.space + (depth * 20.0),
          right: AppDimensions.space,
          top: AppDimensions.spaceSM,
          bottom: AppDimensions.spaceSM,
        ),
        child: Row(
          children: [
            // ── Expand arrow ───────────────────────
            if (node.hasChildren)
              GestureDetector(
                onTap: onExpand,
                child: AnimatedRotation(
                  turns: node.isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: AppDimensions.iconMD,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              const SizedBox(width: AppDimensions.iconMD),

            const SizedBox(width: AppDimensions.spaceXS),

            // ── Checkbox or Radio ──────────────────
            if (node.hasChildren)
              _ParentCheckbox(
                isChecked: isSelected ||
                    node.children.any((c) => c.isSelected),
                onTap: onExpand,
              )
            else
              _LeafRadio(
                isSelected: isSelected,
                onTap: onSelect,
              ),

            const SizedBox(width: AppDimensions.spaceSM),

            // ── Name ───────────────────────────────
            Expanded(
              child: Text(
                node.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Parent Checkbox ────────────────────────────────────────────
class _ParentCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback? onTap;

  const _ParentCheckbox({
    required this.isChecked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color:
              isChecked ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isChecked
                ? AppColors.primary
                : AppColors.border,
            width: 1.5,
          ),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusXS),
        ),
        child: isChecked
            ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

// ── Leaf Radio ─────────────────────────────────────────────────
class _LeafRadio extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const _LeafRadio({required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ── Bottom Actions ─────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  final VoidCallback onClearAll;
  final VoidCallback onDone;
  final bool hasSelection;

  const _BottomActions({
    required this.onClearAll,
    required this.onDone,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceMD,
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onClearAll,
            icon: const Icon(
              Icons.clear_all_rounded,
              color: AppColors.textSecondary,
              size: AppDimensions.iconMD,
            ),
            label: Text(
              'Clear All',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: hasSelection ? onDone : null,
            icon: Icon(
              Icons.check_rounded,
              color: hasSelection
                  ? AppColors.primary
                  : AppColors.textDisabled,
              size: AppDimensions.iconMD,
            ),
            label: Text(
              'Done',
              style: AppTextStyles.buttonMedium.copyWith(
                color: hasSelection
                    ? AppColors.primary
                    : AppColors.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Search ───────────────────────────────────────────────
class _EmptySearchResult extends StatelessWidget {
  final String query;
  const _EmptySearchResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: AppDimensions.iconHuge,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            query.isEmpty
                ? 'No org units found'
                : 'No results for "$query"',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

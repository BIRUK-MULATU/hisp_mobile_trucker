import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/org_unit_tree_node.dart';

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

class _OrgUnitSelectorPageState extends State<OrgUnitSelectorPage> {
  final _searchController = TextEditingController();
  final _secureStorage = SecureStorage();
  final _apiClient = ApiClient();

  List<OrgUnitTreeNode> _roots = [];
  String? _selectedId;
  String? _selectedName;
  bool _isLoading = true;
  String _searchQuery = '';

  // Flat list for display
  List<_DisplayNode> _displayNodes = [];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.preSelectedId;
    _loadOrgUnitTree();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch full org unit tree from DHIS2 ───────────────────
  Future<void> _loadOrgUnitTree() async {
    try {
      final orgUnits = await _secureStorage.getOrgUnits();
      if (orgUnits.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch children for each assigned org unit
      final List<OrgUnitTreeNode> roots = [];

      for (final orgUnit in orgUnits) {
        final id = orgUnit['id'] as String? ?? '';
        final name = orgUnit['displayName'] as String?
            ?? orgUnit['name'] as String? ?? '';

        // Fetch all descendants from DHIS2 API
        final children = await _fetchChildren(id);

        final rootNode = OrgUnitTreeNode(
          id: id,
          name: name,
          level: orgUnit['level'] as int? ?? 1,
          path: orgUnit['path'] as String?,
          children: children,
          isExpanded: true, // auto expand root
          isSelected: _selectedId == id,
          isAssigned: true,
        );
        roots.add(rootNode);
      }

      _roots = roots;
      _buildDisplayList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading org unit tree: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Fetch children from DHIS2 API ─────────────────────────
  Future<List<OrgUnitTreeNode>> _fetchChildren(String parentId) async {
    try {
      final response = await _apiClient.get(
        '/organisationUnits/$parentId',
        queryParameters: {
          'fields': 'id,displayName,level,path,children[id,displayName,level,path,children[id,displayName,level,path,children[id,displayName,level,path]]]',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final childrenJson =
            data['children'] as List<dynamic>? ?? [];
        return childrenJson
            .map((c) => _parseNode(c as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      debugPrint('Error fetching children for $parentId: $e');
    }
    return [];
  }

  // ── Parse node recursively ─────────────────────────────────
  OrgUnitTreeNode _parseNode(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final children = (json['children'] as List<dynamic>? ?? [])
        .map((c) => _parseNode(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return OrgUnitTreeNode(
      id: id,
      name: json['displayName'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      path: json['path'] as String?,
      children: children,
      isExpanded: false,
      isSelected: _selectedId == id,
      isAssigned: false,
    );
  }

  // ── Build flat display list from tree ─────────────────────
  void _buildDisplayList() {
    _displayNodes = [];
    for (final root in _roots) {
      _flattenNode(root, 0);
    }
  }

  void _flattenNode(OrgUnitTreeNode node, int depth) {
    _displayNodes.add(_DisplayNode(node: node, depth: depth));
    if (node.isExpanded) {
      for (final child in node.children) {
        _flattenNode(child, depth + 1);
      }
    }
  }

  // ── Toggle expand/collapse ─────────────────────────────────
  void _toggleExpand(OrgUnitTreeNode node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
      _buildDisplayList();
    });
  }

  // ── Select a node ─────────────────────────────────────────
  void _selectNode(OrgUnitTreeNode node) {
    setState(() {
      _selectedId = node.id;
      _selectedName = node.name;
    });
  }

  // ── Search ────────────────────────────────────────────────
  void _onSearch(String query) {
    setState(() => _searchQuery = query.toLowerCase());
  }

  List<_DisplayNode> get _filteredNodes {
    if (_searchQuery.isEmpty) return _displayNodes;
    return _displayNodes
        .where((n) =>
            n.node.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _clearAll() {
    setState(() {
      _selectedId = null;
      _selectedName = null;
    });
  }

  void _done() {
    Navigator.pop(context, _selectedId != null
        ? {'id': _selectedId, 'name': _selectedName}
        : null);
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

            // ── Tree ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: AppColors.primary),
                          SizedBox(height: AppDimensions.spaceMD),
                          Text('Loading org units...',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : _filteredNodes.isEmpty
                      ? _EmptyState(query: _searchQuery)
                      : ListView.builder(
                          itemCount: _filteredNodes.length,
                          itemBuilder: (context, index) {
                            final item = _filteredNodes[index];
                            return _TreeTile(
                              node: item.node,
                              depth: item.depth,
                              isSelected:
                                  item.node.id == _selectedId,
                              onExpand: item.node.hasChildren
                                  ? () => _toggleExpand(item.node)
                                  : null,
                              onSelect: () =>
                                  _selectNode(item.node),
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
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar(
      {required this.controller, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
        () => setState(() => _focused = _focusNode.hasFocus));
    // Rebuild so the clear button appears/disappears with the text.
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppConstants.animFast),
        curve: Curves.easeOut,
        height: 46,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD),
        decoration: BoxDecoration(
          color: _focused ? Colors.white : AppColors.backgroundGrey,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: _focused ? AppColors.primary : AppColors.divider,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: _focused
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: AppDimensions.iconMD,
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.primary,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  filled: false,
                  hintText: 'Search organisation units',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clear,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.textHint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tree Tile ──────────────────────────────────────────────────
class _TreeTile extends StatelessWidget {
  final OrgUnitTreeNode node;
  final int depth;
  final bool isSelected;
  final VoidCallback? onExpand;
  final VoidCallback? onSelect;

  const _TreeTile({
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
          left: AppDimensions.spaceSM + (depth * 16.0),
          right: AppDimensions.space,
          top: AppDimensions.spaceSM,
          bottom: AppDimensions.spaceSM,
        ),
        child: Row(
          children: [
            // ── Arrow ──────────────────────────────
            SizedBox(
              width: 24,
              child: node.hasChildren
                  ? GestureDetector(
                      onTap: onExpand,
                      child: AnimatedRotation(
                        turns: node.isExpanded ? 0.25 : 0,
                        duration:
                            const Duration(milliseconds: 150),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(width: 4),

            // ── Checkbox or Radio ──────────────────
            node.hasChildren
                ? _Checkbox(
                    isChecked: isSelected,
                    onTap: onExpand,
                  )
                : _Radio(
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

// ── Checkbox widget ────────────────────────────────────────────
class _Checkbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback? onTap;
  const _Checkbox({required this.isChecked, this.onTap});

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
            color:
                isChecked ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusXS),
        ),
        child: isChecked
            ? const Icon(Icons.check_rounded,
                size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── Radio widget ───────────────────────────────────────────────
class _Radio extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;
  const _Radio({required this.isSelected, this.onTap});

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
            icon: const Icon(Icons.clear_all_rounded,
                color: AppColors.textSecondary,
                size: AppDimensions.iconMD),
            label: Text('Clear All',
                style: AppTextStyles.buttonMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: hasSelection ? onDone : null,
            icon: Icon(Icons.check_rounded,
                color: hasSelection
                    ? AppColors.primary
                    : AppColors.textDisabled,
                size: AppDimensions.iconMD),
            label: Text('Done',
                style: AppTextStyles.buttonMedium.copyWith(
                    color: hasSelection
                        ? AppColors.primary
                        : AppColors.textDisabled)),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: AppDimensions.iconHuge,
              color: AppColors.textSecondary),
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

// ── Display Node helper ────────────────────────────────────────
class _DisplayNode {
  final OrgUnitTreeNode node;
  final int depth;
  const _DisplayNode({required this.node, required this.depth});
}

import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../../domain/usecases/get_org_unit_children_usecase.dart';

/// Full-page organisation unit tree opened from the filter panel's
/// tree icon. The user browses the same lazily-loaded hierarchy as
/// the capture workflow, picks a node, and the page pops with it so
/// the caller can apply it as the ORG. UNIT filter.
class OrgUnitFilterPage extends StatefulWidget {
  const OrgUnitFilterPage({super.key});

  @override
  State<OrgUnitFilterPage> createState() => _OrgUnitFilterPageState();
}

class _OrgUnitFilterPageState extends State<OrgUnitFilterPage> {
  final _secureStorage = SecureStorage();
  late final CaptureRepositoryImpl _repository;
  late final GetOrgUnitChildrenUseCase _getChildren;

  List<OrgUnitTreeNode> _roots = [];
  List<_DisplayNode> _displayNodes = [];
  OrgUnitTreeNode? _selected;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = CaptureRepositoryImpl();
    _getChildren = GetOrgUnitChildrenUseCase(_repository);
    _loadRoots();
  }

  Future<void> _loadRoots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orgUnits = await _secureStorage.getOrgUnits();
      final roots = <OrgUnitTreeNode>[];
      for (final orgUnit in orgUnits) {
        final id = orgUnit['id'] as String? ?? '';
        if (id.isEmpty) continue;
        final root = OrgUnitTreeNode(
          id: id,
          name: orgUnit['displayName'] as String? ??
              orgUnit['name'] as String? ??
              '',
          level: orgUnit['level'] as int? ?? 1,
          path: orgUnit['path'] as String?,
          isAssigned: true,
          isExpanded: true,
        );
        // The stored assignment has no child count — resolve the
        // first level now so the root renders correctly expanded.
        root.children.addAll(await _getChildren.call(parentId: id));
        root.childrenLoaded = true;
        roots.add(root);
      }
      _roots = roots;
      _rebuildDisplayList();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _rebuildDisplayList() {
    _displayNodes = [];
    for (final root in _roots) {
      _flatten(root, 0);
    }
  }

  void _flatten(OrgUnitTreeNode node, int depth) {
    _displayNodes.add(_DisplayNode(node: node, depth: depth));
    if (node.isExpanded) {
      for (final child in node.children) {
        _flatten(child, depth + 1);
      }
    }
  }

  Future<void> _toggleExpand(OrgUnitTreeNode node) async {
    if (node.isExpanded) {
      setState(() {
        node.isExpanded = false;
        _rebuildDisplayList();
      });
      return;
    }
    if (!node.childrenLoaded) {
      setState(() => node.isLoadingChildren = true);
      try {
        final children = await _getChildren.call(parentId: node.id);
        node.children.addAll(children);
        node.childrenLoaded = true;
      } catch (_) {
        // Leave the node collapsed; expanding again retries.
        if (mounted) {
          setState(() => node.isLoadingChildren = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load organisation units.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      node.isLoadingChildren = false;
    }
    if (mounted) {
      setState(() {
        node.isExpanded = true;
        _rebuildDisplayList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Organisation Unit',
                style: AppTextStyles.appBarTitle),
            Text(
              'Filter by organisation unit',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildTree()),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space,
              vertical: AppDimensions.spaceMD,
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLG,
              child: ElevatedButton.icon(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.backgroundGrey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                icon: const Icon(Icons.filter_alt_rounded),
                label: Text(
                  'Apply Filter',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: _selected == null
                        ? AppColors.textDisabled
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: AppDimensions.iconHuge,
                  color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('Could not load organisation units',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(_error!,
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceXL),
              ElevatedButton.icon(
                onPressed: _loadRoots,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_displayNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Text(
            'No organisation units assigned to your account.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _displayNodes.length,
      itemBuilder: (context, index) {
        final item = _displayNodes[index];
        final node = item.node;
        final isSelected = node.id == _selected?.id;
        return InkWell(
          onTap: node.hasChildren
              ? () => _toggleExpand(node)
              : () => setState(() => _selected = node),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppDimensions.spaceSM + (item.depth * 16.0),
              right: AppDimensions.space,
              top: AppDimensions.spaceSM,
              bottom: AppDimensions.spaceSM,
            ),
            child: Row(
              children: [
                // ── Arrow / loading spinner ────────────
                SizedBox(
                  width: 24,
                  child: node.isLoadingChildren
                      ? const Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : node.hasChildren
                          ? GestureDetector(
                              onTap: () => _toggleExpand(node),
                              child: AnimatedRotation(
                                turns: node.isExpanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 150),
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

                // ── Radio (every node is selectable) ───
                GestureDetector(
                  onTap: () => setState(() => _selected = node),
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DisplayNode {
  final OrgUnitTreeNode node;
  final int depth;
  const _DisplayNode({required this.node, required this.depth});
}

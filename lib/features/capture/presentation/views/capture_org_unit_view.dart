import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/org_unit_tree_node.dart';
import '../../domain/usecases/get_org_unit_children_usecase.dart';
import '../pages/dataset_selection_page.dart';

/// First step of the Capture workflow, embedded as the home body:
/// the user's assigned org units as tree roots, children fetched
/// lazily one level per expand (the national hierarchy is far too
/// large to load whole), any node selectable.
class CaptureOrgUnitView extends StatefulWidget {
  /// When set (home's app-bar search), it drives the tree filter
  /// and the view's own inline search bar is hidden.
  final String? searchQuery;

  /// Filter-panel ORG. UNIT text — an extra name filter on top of
  /// the search query.
  final String? orgUnitQuery;

  /// Filter-panel SYNC selections (labels from the panel:
  /// 'Synced' / 'UnSynced' / 'Sync Error' / 'SMS Synced'). Non-empty
  /// switches the tree to a flat list of org units whose local work
  /// is in one of those states.
  final Set<String> syncFilters;

  /// Filter-panel DATE window (start inclusive, end exclusive) over
  /// when work was last captured. Non-null also switches to the
  /// flat filtered list.
  final DateTimeRange? dateRange;

  const CaptureOrgUnitView({
    super.key,
    this.searchQuery,
    this.orgUnitQuery,
    this.syncFilters = const {},
    this.dateRange,
  });

  @override
  State<CaptureOrgUnitView> createState() => _CaptureOrgUnitViewState();
}

class _CaptureOrgUnitViewState extends State<CaptureOrgUnitView> {
  final _searchController = TextEditingController();
  final _secureStorage = SecureStorage();
  late final CaptureRepositoryImpl _repository;
  late final GetOrgUnitChildrenUseCase _getChildren;

  List<OrgUnitTreeNode> _roots = [];
  List<_DisplayNode> _displayNodes = [];
  OrgUnitTreeNode? _selected;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  /// Org units matching the sync/date filters, flat and sorted by
  /// name. Null while no such filter is active (tree mode).
  List<OrgUnitTreeNode>? _filteredFlat;

  @override
  void initState() {
    super.initState();
    _repository = CaptureRepositoryImpl();
    _getChildren = GetOrgUnitChildrenUseCase(_repository);
    _loadRoots();
    _applyDataFilters();
    AppSession.instance.service.initialSync.addListener(_onInitialSync);
  }

  /// First-login metadata download progressing in the background:
  /// rebuild for the banner, and reload the tree when the data lands.
  void _onInitialSync() {
    if (!mounted) return;
    if (AppSession.instance.service.initialSync.value ==
        InitialSyncState.done) {
      _loadRoots();
      _applyDataFilters();
    } else {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(CaptureOrgUnitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.syncFilters, widget.syncFilters) ||
        oldWidget.dateRange != widget.dateRange) {
      _applyDataFilters();
    }
  }

  bool get _dataFilterActive =>
      widget.syncFilters.isNotEmpty || widget.dateRange != null;

  Future<void> _applyDataFilters() async {
    if (!_dataFilterActive) {
      if (_filteredFlat != null) setState(() => _filteredFlat = null);
      return;
    }
    final states = <SyncState>{
      for (final label in widget.syncFilters)
        if (label == 'Synced')
          SyncState.synced
        else if (label == 'UnSynced')
          SyncState.pending
        else if (label == 'Sync Error')
          SyncState.error,
      // 'SMS Synced' has no local counterpart (the app does not sync
      // over SMS) — it contributes no state and alone matches nothing.
    };
    var flat = const <OrgUnitTreeNode>[];
    final smsOnly = widget.syncFilters.isNotEmpty && states.isEmpty;
    if (!smsOnly) {
      final ids = await DataValueStore(AppSession.instance.service.db)
          .orgUnitsWithWork(
        states: states,
        from: widget.dateRange?.start,
        to: widget.dateRange?.end,
      );
      flat = await _repository.getOrgUnitsByIds(ids);
    }
    if (mounted) setState(() => _filteredFlat = flat);
  }

  @override
  void dispose() {
    AppSession.instance.service.initialSync.removeListener(_onInitialSync);
    _searchController.dispose();
    super.dispose();
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

  void _select(OrgUnitTreeNode node) {
    setState(() => _selected = node);
  }

  /// External (app-bar) search wins over the inline bar.
  String get _effectiveQuery =>
      widget.searchQuery?.toLowerCase() ?? _searchQuery;

  String get _orgUnitFilterQuery => widget.orgUnitQuery?.toLowerCase() ?? '';

  bool _matchesName(OrgUnitTreeNode node) {
    final name = node.name.toLowerCase();
    final search = _effectiveQuery;
    final filter = _orgUnitFilterQuery;
    return (search.isEmpty || name.contains(search)) &&
        (filter.isEmpty || name.contains(filter));
  }

  List<_DisplayNode> get _filteredNodes {
    // Sync/date filters replace the tree with a flat matching list;
    // both name filters still apply on top.
    final flat = _filteredFlat;
    final nodes = flat != null
        ? [for (final n in flat) _DisplayNode(node: n, depth: 0)]
        : _displayNodes;
    if (_effectiveQuery.isEmpty && _orgUnitFilterQuery.isEmpty) return nodes;
    return nodes.where((n) => _matchesName(n.node)).toList();
  }

  void _continue() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DatasetSelectionPage(
          orgUnitId: selected.id,
          orgUnitName: selected.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepHeader(selectedName: _selected?.name),
        _InitialSyncBanner(
          state: AppSession.instance.service.initialSync.value,
          onRetry: AppSession.instance.service.retryInitialSync,
        ),
        if (widget.searchQuery == null) ...[
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
          ),
          const Divider(height: 1),
        ],
        Expanded(child: _buildTree()),
        const Divider(height: 1),
        _BottomBar(
          enabled: _selected != null,
          onContinue: _continue,
        ),
      ],
    );
  }

  Widget _buildTree() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: AppDimensions.spaceMD),
            Text('Loading organisation units...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
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
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
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
    final nodes = _filteredNodes;
    if (nodes.isEmpty) {
      final query = _effectiveQuery.isNotEmpty
          ? _effectiveQuery
          : _orgUnitFilterQuery;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Text(
            _dataFilterActive
                ? 'No organisation units with matching captured data.'
                : query.isEmpty
                    ? 'No organisation units assigned to your account.'
                    : 'No results for "$query"',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final item = nodes[index];
        return _TreeTile(
          node: item.node,
          depth: item.depth,
          isSelected: item.node.id == _selected?.id,
          onExpand: () => _toggleExpand(item.node),
          onSelect: () => _select(item.node),
        );
      },
    );
  }
}

// ── Initial sync banner ────────────────────────────────────────
/// Shown while the first-login metadata download runs in the
/// background (or after it failed). Invisible otherwise.
class _InitialSyncBanner extends StatelessWidget {
  final InitialSyncState state;
  final VoidCallback onRetry;

  const _InitialSyncBanner({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state != InitialSyncState.running &&
        state != InitialSyncState.failed) {
      return const SizedBox.shrink();
    }
    final failed = state == InitialSyncState.failed;
    return Container(
      width: double.infinity,
      color: failed ? AppColors.error : AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          if (failed)
            const Icon(Icons.cloud_off_rounded,
                color: Colors.white, size: AppDimensions.iconMD)
          else
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                semanticsLabel: 'Downloading data',
              ),
            ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Text(
              failed
                  ? 'Data download was interrupted.'
                  : 'Downloading your data for offline use — '
                      'this happens only once.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ),
          if (failed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

// ── Step header ────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final String? selectedName;
  const _StepHeader({this.selectedName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primarySurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Text(
        selectedName == null
            ? 'Select an organisation unit to capture data for'
            : 'Selected: $selectedName',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
        decoration: BoxDecoration(
          color: _focused ? Colors.white : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: _focused ? AppColors.primary : AppColors.divider,
            width: _focused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: _focused ? AppColors.primary : AppColors.textSecondary,
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
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
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

// ── Tree tile ──────────────────────────────────────────────────
class _TreeTile extends StatelessWidget {
  final OrgUnitTreeNode node;
  final int depth;
  final bool isSelected;
  final VoidCallback onExpand;
  final VoidCallback onSelect;

  const _TreeTile({
    required this.node,
    required this.depth,
    required this.isSelected,
    required this.onExpand,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: node.hasChildren ? onExpand : onSelect,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spaceSM + (depth * 16.0),
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
                          onTap: onExpand,
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
            _Radio(isSelected: isSelected, onTap: onSelect),
            const SizedBox(width: AppDimensions.spaceSM),

            // ── Name ───────────────────────────────
            Expanded(
              child: Text(
                node.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _Radio({required this.isSelected, required this.onTap});

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
            color: isSelected ? AppColors.primary : AppColors.border,
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

// ── Bottom bar ─────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onContinue;

  const _BottomBar({required this.enabled, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceMD,
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeightLG,
        child: ElevatedButton.icon(
          onPressed: enabled ? onContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.backgroundGrey,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(
            'Continue',
            style: AppTextStyles.buttonLarge.copyWith(
              color: enabled ? Colors.white : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _DisplayNode {
  final OrgUnitTreeNode node;
  final int depth;
  const _DisplayNode({required this.node, required this.depth});
}

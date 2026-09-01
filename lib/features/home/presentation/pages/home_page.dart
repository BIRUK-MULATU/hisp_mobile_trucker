import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/onboarding/onboarding_service.dart';
import '../../../../core/onboarding/tour_helper.dart';
import '../../../../core/sync/battery_optimization.dart';
import '../../../../core/sync/manual_sync.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/filter_panel.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import '../../../../shared/widgets/squircle_fab.dart';
import '../../../../shared/widgets/sync_snackbar.dart';
import '../../../capture/domain/entities/org_unit_tree_node.dart';
import '../../../capture/presentation/pages/new_report_page.dart';
import '../../../capture/presentation/pages/org_unit_filter_page.dart';
import '../../../capture/presentation/views/report_period_view.dart';
import '../../../visualization/presentation/views/visualization_view.dart';
import '../widgets/home_app_bar.dart';

/// Home is a shell with two modes behind a toggle:
/// Visualization (left) and Capture (right). Capture shows every
/// report the user has worked on (drafts and completed, across all
/// org units) — the FAB starts a new one via the
/// org unit → dataset → period → section → data entry workflow.
enum HomeMode { visualization, capture }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  HomeMode _mode = HomeMode.visualization;

  // ── App tour targets ────────────────────────────────────────
  // Always-visible anchors only — the filter button is Capture-only
  // and would be missing from the tree on a fresh Visualization-mode
  // launch, which showcaseview can't point at.
  final _modeToggleShowcaseKey = GlobalKey();
  final _menuShowcaseKey = GlobalKey();
  final _searchShowcaseKey = GlobalKey();
  final _syncShowcaseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeStartTour();
      // Sequenced after the tour (not run alongside it) so the
      // showcase overlay and this dialog never fight for the screen on
      // a brand-new user's very first Home visit.
      await _maybeShowBatteryPrompt();
    });
  }

  Future<void> _maybeStartTour({bool force = false}) async {
    if (!mounted) return;
    await maybeStartTour(
      context,
      tourId: 'home',
      keys: [
        _modeToggleShowcaseKey,
        _menuShowcaseKey,
        _searchShowcaseKey,
        _syncShowcaseKey,
      ],
      force: force,
    );
  }

  /// One-time nudge (Android only, ever) to exempt the app from OEM
  /// battery-optimization killing — without it, several manufacturers'
  /// battery managers kill the sync foreground service anyway despite
  /// Android's standard guarantees, silently breaking auto-sync on
  /// reconnect for exactly the field devices that need it most.
  Future<void> _maybeShowBatteryPrompt() async {
    if (await BatteryOptimization.hasPrompted()) return;
    if (await BatteryOptimization.isIgnoringOptimizations()) {
      await BatteryOptimization.markPrompted();
      return;
    }
    await BatteryOptimization.markPrompted();
    if (!mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spaceLG),
        ),
        title: const Text('Keep offline sync reliable',
            style: AppTextStyles.headingSmall),
        content: const Text(
          'To make sure data you capture offline reaches the server as '
          'soon as you\'re back online — even if the app is in the '
          'background — allow HISP Tracker to run without battery '
          'restrictions.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (allow == true) await BatteryOptimization.requestExemption();
  }

  /// "App Tour" drawer item — resets every screen's tour flag, then
  /// replays Home's immediately; the rest auto-replay on next visit.
  void _retakeTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingService.resetAllTours();
      await _maybeStartTour(force: true);
    });
  }

  // ── App-bar controls (search / sync / filters) ─────────────
  bool _showFilters = false;
  bool _searchActive = false;
  String _searchQuery = '';
  AppliedFilter? _dateFilter;
  AppliedFilter? _orgUnitFilter;
  AppliedFilter? _syncFilter;

  // Bumped after a sync, or after returning from the "new report"
  // flow — remounts ReportPeriodView so its list and sync chips
  // reflect the new local state.
  int _syncTick = 0;
  bool _isSyncing = false;

  /// FAB action: the org unit → dataset → period → section → data
  /// entry workflow, on its own page. Reload the report list on
  /// return in case a new report was saved or completed.
  Future<void> _startNewReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewReportPage()),
    );
    if (mounted) setState(() => _syncTick++);
  }

  Future<void> _onSyncTapped() async {
    if (_isSyncing) return;
    if (!AppSession.instance.isLoggedIn) return;

    // Sync results are only visible in Capture mode.
    setState(() => _mode = HomeMode.capture);

    final result = await runManualSync(
      onPushStart: () => setState(() => _isSyncing = true),
    );
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      // Remount the capture view so chips/tree reflect the push.
      if (result.pushedAnything) _syncTick++;
    });
    showSyncResultSnackBar(context, result);
  }

  /// 'From -To' and 'Other' need a real date (range) from a picker;
  /// the other options resolve from their label alone.
  Future<void> _onDateFilterSelected(AppliedFilter? filter) async {
    if (filter == null) {
      setState(() => _dateFilter = null);
      return;
    }
    var applied = filter;
    final now = DateTime.now();
    if (filter.label == 'From -To') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now.add(const Duration(days: 366)),
      );
      if (picked == null || !mounted) return;
      applied = AppliedFilter(
        '${_formatDay(picked.start)} - ${_formatDay(picked.end)}',
        // End exclusive: push it past the last picked day so that
        // whole day is included.
        range: DateTimeRange(
          start: picked.start,
          end: picked.end.add(const Duration(days: 1)),
        ),
      );
    } else if (filter.label == 'Other') {
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2000),
        lastDate: now.add(const Duration(days: 366)),
      );
      if (picked == null || !mounted) return;
      applied = AppliedFilter(
        _formatDay(picked),
        range: DateTimeRange(
          start: picked,
          end: picked.add(const Duration(days: 1)),
        ),
      );
    }
    setState(() => _dateFilter = applied);
  }

  static String _formatDay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Tree icon in the filter panel: pick an org unit from the full
  /// hierarchy on its own page instead of typing its name.
  Future<void> _pickOrgUnitFilter() async {
    final node = await Navigator.push<OrgUnitTreeNode>(
      context,
      MaterialPageRoute(builder: (_) => const OrgUnitFilterPage()),
    );
    if (node != null && mounted) {
      setState(() => _orgUnitFilter = AppliedFilter(node.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read the keyboard inset HERE, above the Scaffold. Inside the
    // body the Scaffold removes viewInsets.bottom (it already resized
    // the body for the keyboard), so any check down there reads 0 and
    // never fires.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchActive: _searchActive,
        filtersShown: _showFilters,
        showFilterButton: _mode == HomeMode.capture,
        isSyncing: _isSyncing,
        // Search targets whichever mode is active: reports (by
        // dataset or org unit name) in Capture, or whichever side of
        // the Dashboards tab's own Server/Local toggle is showing in
        // Visualization (Create New has no list to filter).
        searchHint: _mode == HomeMode.capture
            ? 'Search reports...'
            : 'Search dashboards or charts...',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onSyncTap: _onSyncTapped,
        onListViewTap: () => setState(() => _showFilters = !_showFilters),
        onSearchTap: () => setState(() {
          _searchActive = !_searchActive;
          if (!_searchActive) _searchQuery = '';
        }),
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        menuShowcaseKey: _menuShowcaseKey,
        searchShowcaseKey: _searchShowcaseKey,
        syncShowcaseKey: _syncShowcaseKey,
      ),
      drawer: _HomeDrawer(onRetakeTour: _retakeTour),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The keyboard shrinks the body (resizeToAvoidBottomInset);
          // every fixed-height child left standing must fit what
          // remains. While it is open the mode toggle goes (unusable
          // mid-typing) and the filter panel's cap drops so the
          // capture area below always keeps room for its own search
          // field plus a few tree rows.
          final panelCap = keyboardOpen
              ? (constraints.maxHeight - 160)
                  .clamp(72.0, constraints.maxHeight * 0.6)
              : constraints.maxHeight * 0.6;
          return Column(
            children: [
              // Offstage (never removed): dropping children from the
              // Column shifts the panel's position and Flutter then
              // recreates its whole subtree, stealing focus from the
              // panel's search field right as the keyboard opens.
              Offstage(
                offstage: keyboardOpen,
                child: Column(
                  children: [
                    // The toggle stays a hand-sized pill even on wide
                    // screens.
                    ResponsiveContent(
                      maxWidth: AppBreakpoints.formMaxWidth,
                      child: Showcase(
                        key: _modeToggleShowcaseKey,
                        title: 'Switch modes',
                        description: 'Flip between Visualization (charts) '
                            'and Capture (data entry).',
                        child: SegmentedToggle(
                          items: const [
                            SegmentedToggleItem(
                              label: 'Visualization',
                              icon: Icons.insights_rounded,
                            ),
                            SegmentedToggleItem(
                              label: 'Capture',
                              icon: Icons.edit_note_rounded,
                            ),
                          ],
                          index: _mode.index,
                          // A query typed for one mode means nothing in the
                          // other — close the search on switch.
                          onChanged: (i) => setState(() {
                            _mode = HomeMode.values[i];
                            _searchActive = false;
                            _searchQuery = '';
                          }),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                  ],
                ),
              ),
              // Filters belong to the Capture workflow, so the panel lives
              // inside the capture area rather than above the mode toggle.
              // The cap sits OUTSIDE the AnimatedSize so a keyboard-driven
              // cap change binds immediately — inside, the 200ms size
              // animation would overflow the shrunken body mid-flight.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: panelCap),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _showFilters && _mode == HomeMode.capture
                      ? SingleChildScrollView(
                          // The expanded panel can outgrow the cap; it
                          // scrolls inside it and focusing the panel's
                          // search field auto-scrolls it into view.
                          child: ResponsiveContent(
                            child: FilterPanel(
                              dateFilter: _dateFilter,
                              orgUnitFilter: _orgUnitFilter,
                              syncFilter: _syncFilter,
                              onDateChanged: _onDateFilterSelected,
                              onOrgUnitChanged: (f) =>
                                  setState(() => _orgUnitFilter = f),
                              onSyncChanged: (f) =>
                                  setState(() => _syncFilter = f),
                              onOpenOrgUnitTree: _pickOrgUnitFilter,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: ResponsiveContent(
                  // IndexedStack keeps both modes' state alive across
                  // toggles — a plain ternary here would destroy and
                  // recreate ReportPeriodView on every switch back,
                  // re-triggering its full reload each time.
                  child: IndexedStack(
                    index: _mode.index,
                    children: [
                      VisualizationView(
                        searchQuery: _searchActive ? _searchQuery : null,
                      ),
                      ReportPeriodView(
                        key: ValueKey('reports-$_syncTick'),
                        searchQuery: _searchActive ? _searchQuery : null,
                        orgUnitQuery: _orgUnitFilter?.label,
                        syncFilters: _syncFilter?.label.split(', ').toSet() ??
                            const {},
                        dateRange: _dateFilter == null
                            ? null
                            : resolveDateFilter(_dateFilter!, DateTime.now()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // "New report" — Capture mode only, and hidden while the
      // keyboard is up so it never overlaps a focused filter field.
      floatingActionButton: _mode == HomeMode.capture && !keyboardOpen
          ? SquircleFab(onPressed: _startNewReport)
          : null,
    );
  }
}

// ── Drawer (unchanged behavior) ────────────────────────────────
class _HomeDrawer extends StatelessWidget {
  final VoidCallback? onRetakeTour;
  const _HomeDrawer({this.onRetakeTour});

  Future<void> _logout(BuildContext context) async {
    final secureStorage = SecureStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: ApiClient(),
        secureStorage: secureStorage,
      ),
      secureStorage: secureStorage,
    );
    await LogoutUseCase(repository).call();
    if (context.mounted) context.go(AppRouter.login);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spaceLG),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.info_rounded,
                  color: Colors.white, size: AppDimensions.iconXL),
            ),
            SizedBox(width: AppDimensions.space),
            Expanded(
              child:
                  Text(AppConstants.appName, style: AppTextStyles.headingSmall),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version ${AppConstants.appVersion}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text(
                'RDHIS2 Mobile App is the official mobile data '
                'collection and reporting application of the Ministry '
                'of Health, built on the DHIS2 Health Management '
                'Information System. It enables health workers to '
                'record, review, and submit aggregate health data for '
                'their facility directly from a mobile device.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              const Text(
                'The application is designed for the realities of '
                'field work: data can be entered at any time and '
                'synchronized with the national DHIS2 server whenever '
                'a connection is available, helping keep facility '
                'reports timely, complete, and accurate.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFDDDDDD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Blue header block ──────────────────────────────
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).padding.top + 110,
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: AppDimensions.spaceLG,
              right: AppDimensions.spaceLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Health Management Information System',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),

          // ── Main items ─────────────────────────────────────
          _DrawerItem(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.settings_rounded,
            label: 'Setting',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.settings);
            },
          ),
          _DrawerItem(
            icon: Icons.travel_explore_rounded,
            label: 'App Tour',
            onTap: () {
              Navigator.pop(context);
              onRetakeTour?.call();
            },
          ),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: () => _logout(context),
          ),

          const SizedBox(height: AppDimensions.spaceGiant),

          // ── About section between dividers ─────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
            child: Divider(color: Colors.black45, height: 1),
          ),
          _DrawerItem(
            icon: Icons.info_rounded,
            label: 'About',
            filledCircleIcon: true,
            onTap: () {
              Navigator.pop(context);
              _showAbout(context);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
            child: Divider(color: Colors.black45, height: 1),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filledCircleIcon;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filledCircleIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: AppDimensions.space,
        ),
        child: Row(
          children: [
            filledCircleIcon
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'i',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Icon(icon,
                    color: AppColors.primary, size: AppDimensions.iconXL),
            const SizedBox(width: AppDimensions.spaceLG),
            Text(label, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

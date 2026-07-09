import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/data/completeness.dart';
import '../../../../core/data/data_value_store.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/drift_sync_manager.dart';
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
import '../../../capture/presentation/views/capture_org_unit_view.dart';
import '../widgets/home_app_bar.dart';

/// Home is a shell with two modes behind a toggle:
/// Visualization (left) and Capture (right). Capture starts the
/// org unit → dataset → section → period → data entry workflow.
enum HomeMode { visualization, capture }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  HomeMode _mode = HomeMode.visualization;

  // ── App-bar controls (search / sync / filters) ─────────────
  bool _showFilters = false;
  bool _searchActive = false;
  String _searchQuery = '';
  AppliedFilter? _dateFilter;
  AppliedFilter? _orgUnitFilter;
  AppliedFilter? _syncFilter;

  // Bumped after a sync — remounts the capture view so the sync
  // chips and org unit tree reflect the new local state.
  int _syncTick = 0;
  bool _isSyncing = false;

  Future<void> _onSyncTapped() async {
    if (_isSyncing) return;
    final session = AppSession.instance;
    if (!session.isLoggedIn) return;

    // Sync results are only visible in Capture mode.
    setState(() => _mode = HomeMode.capture);

    final db = session.service.db;
    final store = DataValueStore(db);
    final pendingValues = await store.pendingCount();
    final pendingCompletions = (await CompletenessStore(db).pending()).length;
    final pendingTotal = pendingValues + pendingCompletions;

    // Fresh reachability probe — the cached flag can be up to 30s stale.
    await ConnectivityService.instance.checkNow();
    final online = ConnectivityService.instance.online ?? false;
    if (!mounted) return;

    if (!online) {
      _showSyncMessage(
        pendingTotal > 0
            ? 'No internet connection — $pendingTotal unsynced '
                '${pendingTotal == 1 ? 'entry' : 'entries'} will upload '
                'automatically when you are back online.'
            : 'No internet connection.',
        color: AppColors.error,
      );
      return;
    }
    if (pendingTotal == 0) {
      _showSyncMessage('Everything is already synced.',
          color: AppColors.success);
      return;
    }

    setState(() => _isSyncing = true);
    try {
      await DriftSyncManager.instance.pushPending();
      // Refresh metadata too, but a metadata hiccup must not mask a
      // successful upload.
      try {
        await DriftSyncManager.instance.pullLatest();
      } catch (e) {
        debugPrint('metadata refresh after sync failed: $e');
      }
      final remaining = await store.pendingCount() +
          (await CompletenessStore(db).pending()).length;
      if (!mounted) return;
      if (remaining == 0) {
        _showSyncMessage(
          'Sync complete — $pendingTotal '
          '${pendingTotal == 1 ? 'entry' : 'entries'} uploaded.',
          color: AppColors.success,
        );
      } else {
        _showSyncMessage(
          '$remaining of $pendingTotal entries could not be uploaded '
          'and will retry later.',
          color: AppColors.warning,
        );
      }
    } catch (e) {
      debugPrint('manual sync failed: $e');
      if (mounted) {
        _showSyncMessage(
          'Sync failed — your entries are safe on this device and '
          'will retry automatically.',
          color: AppColors.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncTick++;
        });
      }
    }
  }

  void _showSyncMessage(String message, {required Color color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchActive: _searchActive,
        filtersShown: _showFilters,
        isSyncing: _isSyncing,
        searchHint: 'Search organisation units...',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onSyncTap: _onSyncTapped,
        onListViewTap: () => setState(() => _showFilters = !_showFilters),
        onSearchTap: () => setState(() {
          _searchActive = !_searchActive;
          if (!_searchActive) {
            _searchQuery = '';
          } else {
            // Searching targets the org unit tree — make it visible.
            _mode = HomeMode.capture;
          }
        }),
        onSearchChanged: (query) => setState(() => _searchQuery = query),
      ),
      drawer: const _HomeDrawer(),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showFilters
                ? FilterPanel(
                    dateFilter: _dateFilter,
                    orgUnitFilter: _orgUnitFilter,
                    syncFilter: _syncFilter,
                    onDateChanged: (f) => setState(() => _dateFilter = f),
                    onOrgUnitChanged: (f) => setState(() => _orgUnitFilter = f),
                    onSyncChanged: (f) => setState(() => _syncFilter = f),
                  )
                : const SizedBox.shrink(),
          ),
          // The toggle stays a hand-sized pill even on wide screens.
          ResponsiveContent(
            maxWidth: AppBreakpoints.formMaxWidth,
            child: _ModeToggleBar(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ResponsiveContent(
              child: _mode == HomeMode.visualization
                  ? const _VisualizationPlaceholder()
                  : CaptureOrgUnitView(
                      key: ValueKey('capture-$_syncTick'),
                      searchQuery: _searchActive ? _searchQuery : null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode toggle bar ────────────────────────────────────────────
class _ModeToggleBar extends StatelessWidget {
  final HomeMode mode;
  final ValueChanged<HomeMode> onChanged;

  const _ModeToggleBar({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _ModeButton(
              label: 'Visualization',
              icon: Icons.insights_rounded,
              isActive: mode == HomeMode.visualization,
              onTap: () => onChanged(HomeMode.visualization),
            ),
            _ModeButton(
              label: 'Capture',
              icon: Icons.edit_note_rounded,
              isActive: mode == HomeMode.capture,
              onTap: () => onChanged(HomeMode.capture),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppConstants.animNormal),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconMD,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visualization placeholder ──────────────────────────────────
class _VisualizationPlaceholder extends StatelessWidget {
  const _VisualizationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            const Text(
              'Visualizations coming soon',
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              'Dashboards and charts for your organisation unit '
              'will appear here.\nSwitch to Capture to start '
              'entering data.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer (unchanged behavior) ────────────────────────────────
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

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
                'HISP Mobile Tracker is the official mobile data '
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
              const SizedBox(height: AppDimensions.spaceLG),
              Text(
                'Developed by HISP Ethiopia in collaboration with the '
                'Ministry of Health. For assistance, please contact '
                'your system administrator or district health office.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
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

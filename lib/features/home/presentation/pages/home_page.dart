import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../dataset_detail/presentation/pages/dataset_detail_page.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/usecases/get_datasets_usecase.dart';
import '../../domain/usecases/sync_dataset_usecase.dart';
import '../bloc/home_bloc.dart';
import '../widgets/dataset_card.dart';
import '../widgets/home_app_bar.dart';
import '../../../../shared/widgets/filter_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final remoteDataSource =
        HomeRemoteDataSourceImpl(apiClient: apiClient);
    final repository =
        HomeRepositoryImpl(remoteDataSource: remoteDataSource);

    return BlocProvider(
      create: (_) => HomeBloc(
        getDataSetsUseCase: GetDataSetsUseCase(repository),
        syncDataSetUseCase: SyncDataSetUseCase(repository),
      )..add(const HomeLoadDataSets()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showFilters = false;
  bool _searchActive = false;
  String _searchQuery = '';
  AppliedFilter? _dateFilter;
  AppliedFilter? _orgUnitFilter;
  AppliedFilter? _syncFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final isSyncing = state is HomeLoaded && state.isSyncing;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.backgroundGrey,
          appBar: HomeAppBar(
            isSyncing: isSyncing,
            searchActive: _searchActive,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onSyncTap: () =>
                context.read<HomeBloc>().add(const HomeSyncAll()),
            onListViewTap: () =>
                setState(() => _showFilters = !_showFilters),
            onSearchTap: () => setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) _searchQuery = '';
            }),
            onSearchChanged: (query) =>
                setState(() => _searchQuery = query),
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
                        onDateChanged: (f) =>
                            setState(() => _dateFilter = f),
                        onOrgUnitChanged: (f) =>
                            setState(() => _orgUnitFilter = f),
                        onSyncChanged: (f) =>
                            setState(() => _syncFilter = f),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  List<DataSetEntity> _applyFilters(List<DataSetEntity> dataSets) {
    var result = dataSets;

    // ── Search ──────────────────────────────────────────
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where((d) => d.name.toLowerCase().contains(query))
          .toList();
    }

    // ── Sync status ─────────────────────────────────────
    // The panel stores multi-selections as a comma-joined label
    // ("Synced, UnSynced"). Options with no data equivalent yet
    // (Sync Error, SMS Synced) match nothing.
    final syncLabels = _syncFilter?.label.split(', ').toSet();
    if (syncLabels != null && syncLabels.isNotEmpty) {
      result = result.where((d) {
        final isSynced = d.syncStatus == SyncStatus.synced;
        return (syncLabels.contains('Synced') && isSynced) ||
            (syncLabels.contains('UnSynced') && !isSynced);
      }).toList();
    }

    // Date and org unit filters are not applied yet: datasets carry
    // no date, and org unit assignments aren't fetched. Wire them
    // here once that data exists (see _dateFilter/_orgUnitFilter).
    return result;
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is HomeLoading) {
      return const AppLoader(message: 'Loading datasets...');
    }
    if (state is HomeError) {
      return _ErrorView(
        message: state.message,
        onRetry: () =>
            context.read<HomeBloc>().add(const HomeLoadDataSets()),
      );
    }
    if (state is HomeLoaded) {
      if (state.dataSets.isEmpty) return const _EmptyView();
      final dataSets = _applyFilters(state.dataSets);
      if (dataSets.isEmpty) return const _EmptyView();
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<HomeBloc>().add(const HomeRefresh());
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceMD),
          itemCount: dataSets.length,
          itemBuilder: (context, index) {
            final dataSet = dataSets[index];
            return DataSetCard(
              dataSet: dataSet,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DatasetDetailPage(
                      dataSetId: dataSet.id,
                      dataSetName: dataSet.name,
                      periodType: dataSet.periodType, // ← pass it
                    ),
                  ),
                );
              },
              onSync: () => context
                  .read<HomeBloc>()
                  .add(HomeSyncDataSet(dataSet.id)),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

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
              child: Text(AppConstants.appName,
                  style: AppTextStyles.headingSmall),
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
                'HISP Mobile Tracker is a health data collection and '
                'reporting application for the Ministry of Health. '
                'It allows health workers to enter, review and sync '
                'aggregate dataset values with the central DHIS2 '
                    'HISP Mobile Tracker is a health data collection and '
                    'reporting application for the Ministry of Health. '
                    'It allows health workers to enter, review and sync '
                    'aggregate dataset values with the central DHIS2 '                'HISP Mobile Tracker is a health data collection and '
                    'reporting application for the Ministry of Health. '
                    'It allows health workers to enter, review and sync '
                    'aggregate dataset values with the central DHIS2 '                'HISP Mobile Tracker is a health data collection and '
                    'reporting application for the Ministry of Health. '
                    'It allows health workers to enter, review and sync '
                    'aggregate dataset values with the central DHIS2 '
                'server, even in areas with limited connectivity.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Text(
                'Developed by HISP Ethiopia in collaboration with the '
                'Ministry of Health. For support, contact your system '
                'administrator.',
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
            padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG),
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
            padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG),
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
                    color: AppColors.primary,
                    size: AppDimensions.iconXL),
            const SizedBox(width: AppDimensions.spaceLG),
            Text(label, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
            const Text('Could not load datasets',
                style: AppTextStyles.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(message,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceXXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: AppDimensions.iconHuge,
              color: AppColors.textSecondary),
          SizedBox(height: AppDimensions.spaceLG),
          Text('No datasets found',
              style: AppTextStyles.headingSmall),
          SizedBox(height: AppDimensions.spaceSM),
          Text(
            'Check your server connection\nor contact your administrator.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

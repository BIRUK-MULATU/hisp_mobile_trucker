import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../dataset_detail/presentation/pages/dataset_detail_page.dart';
import '../../data/datasources/home_remote_datasource.dart';
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
  bool _showFilters = false;
  AppliedFilter? _dateFilter;
  AppliedFilter? _orgUnitFilter;
  AppliedFilter? _syncFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final isSyncing = state is HomeLoaded && state.isSyncing;
        return Scaffold(
          backgroundColor: AppColors.backgroundGrey,
          appBar: HomeAppBar(
            isSyncing: isSyncing,
            onMenuTap: () => Scaffold.of(context).openDrawer(),
            onSyncTap: () =>
                context.read<HomeBloc>().add(const HomeSyncAll()),
            onListViewTap: () =>
                setState(() => _showFilters = !_showFilters),
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
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<HomeBloc>().add(const HomeRefresh());
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceMD),
          itemCount: state.dataSets.length,
          itemBuilder: (context, index) {
            final dataSet = state.dataSets[index];
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top +
                  AppDimensions.spaceXL,
              bottom: AppDimensions.spaceXL,
              left: AppDimensions.space,
              right: AppDimensions.space,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconXL),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                Text('HISP User',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: Colors.white)),
                Text('admin@dhis2.org',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined,
                color: AppColors.primary),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined,
                color: AppColors.primary),
            title: const Text('Sync'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: AppColors.primary),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded,
                color: AppColors.error),
            title: Text('Logout',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.error)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
        ],
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
            Text('Could not load datasets',
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open_rounded,
              size: AppDimensions.iconHuge,
              color: AppColors.textSecondary),
          const SizedBox(height: AppDimensions.spaceLG),
          Text('No datasets found',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: AppDimensions.spaceSM),
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

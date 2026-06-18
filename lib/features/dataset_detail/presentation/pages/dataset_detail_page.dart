import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/datasources/dataset_detail_remote_datasource.dart';
import '../../data/repositories/dataset_detail_repository_impl.dart';
import '../../domain/usecases/get_records_usecase.dart';
import '../../domain/usecases/create_record_usecase.dart';
import '../bloc/dataset_detail_bloc.dart';
import 'add_record_page.dart';

class DatasetDetailPage extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;

  const DatasetDetailPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
  });

  @override
  Widget build(BuildContext context) {
    final repository = DatasetDetailRepositoryImpl(
      remoteDataSource: DatasetDetailRemoteDataSourceImpl(
        apiClient: ApiClient(),
      ),
    );

    return BlocProvider(
      create: (_) => DatasetDetailBloc(
        getRecordsUseCase: GetRecordsUseCase(repository),
        createRecordUseCase: CreateRecordUseCase(repository),
      )..add(DatasetDetailLoad(dataSetId)),
      child: _DatasetDetailView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
      ),
    );
  }
}

class _DatasetDetailView extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;

  const _DatasetDetailView({
    required this.dataSetId,
    required this.dataSetName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _DetailAppBar(dataSetName: dataSetName),
      body: BlocBuilder<DatasetDetailBloc, DatasetDetailState>(
        builder: (context, state) {
          if (state is DatasetDetailLoading) {
            return const AppLoader(message: 'Loading records...');
          }
          if (state is DatasetDetailLoaded && state.isEmpty) {
            return const _EmptyState();
          }
          if (state is DatasetDetailLoaded && !state.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<DatasetDetailBloc>()
                    .add(DatasetDetailRefresh(dataSetId));
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.separated(
                padding:
                    const EdgeInsets.all(AppDimensions.space),
                itemCount: state.records.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.spaceSM),
                itemBuilder: (context, index) {
                  final record = state.records[index];
                  return _RecordCard(record: record);
                },
              ),
            );
          }
          if (state is DatasetDetailError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context
                  .read<DatasetDetailBloc>()
                  .add(DatasetDetailLoad(dataSetId)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddRecord(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: AppDimensions.iconXL,
        ),
      ),
    );
  }

  // ── Fix: store bloc reference before async gap ─────────────
  void _onAddRecord(BuildContext context) {
    final bloc = context.read<DatasetDetailBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          dataSetId: dataSetId,
          dataSetName: dataSetName,
        ),
      ),
    ).then((_) {
      bloc.add(DatasetDetailRefresh(dataSetId));
    });
  }
}

// ── AppBar ─────────────────────────────────────────────────────
class _DetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String dataSetName;
  const _DetailAppBar({required this.dataSetName});

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        dataSetName,
        style: AppTextStyles.appBarTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_rounded, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.format_list_bulleted_rounded,
              color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: AppDimensions.spaceXS),
      ],
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(AppDimensions.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: AppDimensions.iconXXL,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'There are no data. Click "+" to\nadd new a new record',
              style: AppTextStyles.bodyMedium.copyWith(
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

// ── Record Card ────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final dynamic record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
              size: AppDimensions.iconMD,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.periodName ?? record.periodId,
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  record.orgUnitName ?? record.orgUnitId,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.message, required this.onRetry});

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
            Text('Could not load records',
                style: AppTextStyles.headingSmall),
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

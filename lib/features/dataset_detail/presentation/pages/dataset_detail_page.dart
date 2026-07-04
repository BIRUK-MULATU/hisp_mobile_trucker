import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/datasources/dataset_detail_remote_datasource.dart';
import '../../data/repositories/dataset_detail_repository_impl.dart';
import '../../domain/entities/data_record_entity.dart';
import '../../domain/usecases/get_records_usecase.dart';
import '../../domain/usecases/create_record_usecase.dart';
import '../bloc/dataset_detail_bloc.dart';
import 'add_record_page.dart';

class DatasetDetailPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType; // ← passed from home page

  const DatasetDetailPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    this.periodType = 'Monthly',
  });

  @override
  State<DatasetDetailPage> createState() => _DatasetDetailPageState();
}

class _DatasetDetailPageState extends State<DatasetDetailPage> {
  final _secureStorage = SecureStorage();
  String? _orgUnitId;
  bool _loadingOrgUnit = true;

  @override
  void initState() {
    super.initState();
    _loadOrgUnit();
  }

  Future<void> _loadOrgUnit() async {
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    if (mounted) {
      setState(() {
        _orgUnitId = orgUnit?['id'] as String?;
        _loadingOrgUnit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingOrgUnit) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: AppLoader(message: 'Loading records...'),
      );
    }

    final repository = DatasetDetailRepositoryImpl(
      remoteDataSource: DatasetDetailRemoteDataSourceImpl(
        apiClient: ApiClient(),
      ),
    );

    return BlocProvider(
      create: (_) => DatasetDetailBloc(
        getRecordsUseCase: GetRecordsUseCase(repository),
        createRecordUseCase: CreateRecordUseCase(repository),
      )..add(DatasetDetailLoad(widget.dataSetId, _orgUnitId ?? '')),
      child: _DatasetDetailView(
        dataSetId: widget.dataSetId,
        dataSetName: widget.dataSetName,
        periodType: widget.periodType,
        orgUnitId: _orgUnitId ?? '',
      ),
    );
  }
}

class _DatasetDetailView extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String orgUnitId;

  const _DatasetDetailView({
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
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
                    .add(DatasetDetailRefresh(dataSetId, orgUnitId));
                await Future.delayed(
                    const Duration(seconds: 1));
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
                  .add(DatasetDetailLoad(dataSetId, orgUnitId)),
            );
          }
          // Initial state (load event not processed yet) —
          // keep the spinner up instead of a blank page.
          return const AppLoader(message: 'Loading records...');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddRecord(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: AppDimensions.iconXL),
      ),
    );
  }

  void _onAddRecord(BuildContext context) {
    final bloc = context.read<DatasetDetailBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          dataSetId: dataSetId,
          dataSetName: dataSetName,
          periodType: periodType, // ← pass period type
        ),
      ),
    ).then((_) {
      bloc.add(DatasetDetailRefresh(dataSetId, orgUnitId));
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
      title: Text(dataSetName,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
            icon:
                const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded,
                color: Colors.white),
            onPressed: () {}),
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
        padding: const EdgeInsets.all(AppDimensions.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined,
                  size: AppDimensions.iconXXL,
                  color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'There are no data. Click "+" to\nadd new a new record',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.6),
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
  final DataRecordEntity record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCompleted = record.status == RecordStatus.complete;
    final registeredDate = record.createdAt ?? record.lastUpdated;

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Period + Date ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  EthiopianCalendar.formatPeriodId(record.periodId),
                  style: AppTextStyles.labelLarge,
                ),
              ),
              if (registeredDate != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(registeredDate),
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXXS),

          // ── Registered in ────────────────────────────────
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
              children: [
                const TextSpan(
                  text: 'Registered in : ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      record.orgUnitName ?? record.orgUnitId,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),

          // ── Completed status + Sync badge ────────────────
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: AppDimensions.iconSM,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spaceXXS),
              Text(
                isCompleted ? 'Completed' : 'Incomplete',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isCompleted
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _SyncBadge(isSynced: record.isSynced),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sync Badge ─────────────────────────────────────────────────
class _SyncBadge extends StatelessWidget {
  final bool isSynced;
  const _SyncBadge({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isSynced
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isSynced
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Text(
        isSynced ? 'Synced' : 'Unsync',
        style: AppTextStyles.caption.copyWith(
          color: isSynced ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
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
            const Text('Could not load records',
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

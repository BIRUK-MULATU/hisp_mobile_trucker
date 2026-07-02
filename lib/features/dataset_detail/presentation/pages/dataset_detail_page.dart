import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widgets/record_list_card.dart';
import 'add_record_page.dart';

class DatasetDetailPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;

  const DatasetDetailPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    this.periodType = 'Monthly',
  });

  @override
  State<DatasetDetailPage> createState() =>
      _DatasetDetailPageState();
}

class _DatasetDetailPageState extends State<DatasetDetailPage> {
  final _secureStorage = SecureStorage();
  String _orgUnitId = '';

  @override
  void initState() {
    super.initState();
    _loadOrgUnit();
  }

  Future<void> _loadOrgUnit() async {
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    if (mounted && orgUnit != null) {
      setState(() {
        _orgUnitId = orgUnit['id'] as String? ?? '';
      });
    }
  }

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
      )..add(DatasetDetailLoad(widget.dataSetId, _orgUnitId)),
      child: _DatasetDetailView(
        dataSetId: widget.dataSetId,
        dataSetName: widget.dataSetName,
        periodType: widget.periodType,
        orgUnitId: _orgUnitId,
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
      backgroundColor: AppColors.backgroundGrey,
      appBar: _DetailAppBar(dataSetName: dataSetName),
      body: BlocBuilder<DatasetDetailBloc, DatasetDetailState>(
        builder: (context, state) {
          if (state is DatasetDetailLoading) {
            return const AppLoader(
                message: 'Loading records...');
          }
          if (state is DatasetDetailLoaded && state.isEmpty) {
            return const _EmptyState();
          }
          if (state is DatasetDetailLoaded && !state.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<DatasetDetailBloc>().add(
                    DatasetDetailRefresh(dataSetId, orgUnitId));
                await Future.delayed(
                    const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spaceMD),
                itemCount: state.records.length,
                itemBuilder: (context, index) {
                  final record = state.records[index];
                  return RecordListCard(
                    period: record.periodId,
                    orgUnitName:
                        record.orgUnitName ?? record.orgUnitId,
                    date: _formatDate(record.createdAt),
                    isCompleted:
                        record.status == RecordStatus.complete,
                    syncStatus: index % 2 == 0
                        ? RecordSyncStatus.synced
                        : RecordSyncStatus.unsynced,
                    onTap: () {},
                  );
                },
              ),
            );
          }
          if (state is DatasetDetailError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context
                  .read<DatasetDetailBloc>()
                  .add(DatasetDetailLoad(
                      dataSetId, orgUnitId)),
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
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: AppDimensions.iconXL),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      final now = EthiopianCalendar.toEthiopian(DateTime.now());
      return '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}';
    }
    final eth = EthiopianCalendar.toEthiopian(date);
    return '${eth.day.toString().padLeft(2, '0')}/'
        '${eth.month.toString().padLeft(2, '0')}/'
        '${eth.year}';
  }

  void _onAddRecord(BuildContext context) {
    final bloc = context.read<DatasetDetailBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordPage(
          dataSetId: dataSetId,
          dataSetName: dataSetName,
          periodType: periodType,
        ),
      ),
    ).then((result) {
      if (result != null) {
        bloc.add(DatasetDetailRefresh(dataSetId, orgUnitId));
      }
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
          icon: const Icon(Icons.sync_rounded,
              color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(
              Icons.format_list_bulleted_rounded,
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
              child: const Icon(Icons.inbox_outlined,
                  size: AppDimensions.iconXXL,
                  color: AppColors.primary),
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

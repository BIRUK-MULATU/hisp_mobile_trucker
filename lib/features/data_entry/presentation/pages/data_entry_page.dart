import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/datasources/data_entry_remote_datasource.dart';
import '../../data/repositories/data_entry_repository_impl.dart';
import '../../domain/usecases/get_data_elements_usecase.dart';
import '../../domain/usecases/save_data_values_usecase.dart';
import '../bloc/data_entry_bloc.dart';
import '../widgets/data_entry_table.dart';

class DataEntryPage extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;
  final String orgUnitId;
  final String orgUnitName;
  final String period;
  final String periodType;
  final DataEntryBloc? preloadedBloc;

  const DataEntryPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
    this.preloadedBloc,
  });

  @override
  Widget build(BuildContext context) {
    // If bloc already created and loading — reuse it
    if (preloadedBloc != null) {
      return _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
      );
    }

    // Fallback — create fresh bloc if navigated directly
    final repository = DataEntryRepositoryImpl(
      remoteDataSource: DataEntryRemoteDataSourceImpl(
        apiClient: ApiClient(),
      ),
    );

    return BlocProvider(
      create: (_) => DataEntryBloc(
        getDataElementsUseCase:
            GetDataElementsUseCase(repository),
        saveDataValuesUseCase:
            SaveDataValuesUseCase(repository),
        repository: repository,
      )..add(DataEntryLoad(
          dataSetId: dataSetId,
          orgUnitId: orgUnitId,
          period: period,
        )),
      child: _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
      ),
    );
  }
}

class _DataEntryView extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;
  final String orgUnitId;
  final String orgUnitName;
  final String period;
  final String periodType;

  const _DataEntryView({
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DataEntryBloc, DataEntryState>(
      listener: (context, state) {
        if (state is DataEntrySaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data saved successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
        if (state is DataEntryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
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
            const SizedBox(width: AppDimensions.spaceXS),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period + Org Unit sub-header ────────
            _SubHeader(
                period: period, orgUnitName: orgUnitName),
            const Divider(height: 1, color: AppColors.divider),

            // ── Table ───────────────────────────────
            Expanded(
              child: BlocBuilder<DataEntryBloc, DataEntryState>(
                builder: (context, state) {
                  if (state is DataEntryLoading) {
                    return const AppLoader(
                        message: 'Loading form...');
                  }
                  if (state is DataEntryError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<DataEntryBloc>().add(
                                DataEntryLoad(
                                  dataSetId: dataSetId,
                                  orgUnitId: orgUnitId,
                                  period: period,
                                ),
                              ),
                    );
                  }
                  if (state is DataEntryLoaded) {
                    return DataEntryTable(
                      dataElements: state.dataElements,
                      dataValues: state.dataValues,
                      orgUnitId: orgUnitId,
                      period: period,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton:
            BlocBuilder<DataEntryBloc, DataEntryState>(
          builder: (context, state) {
            final isSaving = state is DataEntryLoaded &&
                state.isSaving;
            final hasChanges = state is DataEntryLoaded &&
                state.hasChanges;
            return FloatingActionButton(
              onPressed: isSaving
                  ? null
                  : () => context
                      .read<DataEntryBloc>()
                      .add(const DataEntrySave()),
              backgroundColor: hasChanges
                  ? AppColors.primary
                  : AppColors.primaryLight,
              elevation: 4,
              shape: const CircleBorder(),
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white))
                  : const Icon(Icons.check_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconXL),
            );
          },
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String period;
  final String orgUnitName;
  const _SubHeader(
      {required this.period, required this.orgUnitName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space,
          vertical: AppDimensions.spaceSM),
      child: Row(
        children: [
          Text(
            EthiopianCalendar.formatPeriodId(period),
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: AppDimensions.spaceXL),
          Expanded(
            child: Text(orgUnitName,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: AppDimensions.iconHuge,
                color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            Text('Could not load form',
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

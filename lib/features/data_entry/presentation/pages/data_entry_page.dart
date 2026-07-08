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

  /// When set, the form covers a single dataset section.
  final String? sectionId;
  final String? sectionName;

  final DataEntryBloc? preloadedBloc;

  const DataEntryPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
    this.sectionId,
    this.sectionName,
    this.preloadedBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (preloadedBloc != null) {
      return _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
        sectionId: sectionId,
        sectionName: sectionName,
      );
    }

    final repository = DataEntryRepositoryImpl(
      remoteDataSource: DataEntryRemoteDataSourceImpl(
        apiClient: ApiClient(),
      ),
    );

    return BlocProvider(
      create: (_) => DataEntryBloc(
        getDataElementsUseCase: GetDataElementsUseCase(repository),
        saveDataValuesUseCase: SaveDataValuesUseCase(repository),
        repository: repository,
      )..add(DataEntryLoad(
          dataSetId: dataSetId,
          orgUnitId: orgUnitId,
          period: period,
          sectionId: sectionId,
        )),
      child: _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
        sectionId: sectionId,
        sectionName: sectionName,
      ),
    );
  }
}

class _DataEntryView extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String orgUnitId;
  final String orgUnitName;
  final String period;
  final String periodType;
  final String? sectionId;
  final String? sectionName;

  const _DataEntryView({
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
    this.sectionId,
    this.sectionName,
  });

  @override
  State<_DataEntryView> createState() => _DataEntryViewState();
}

class _DataEntryViewState extends State<_DataEntryView> {
  bool _isSaving = false;
  bool _isCompleting = false;

  // ── Sync tapped — reload values from the server ───────────
  void _onSyncTapped() {
    final bloc = context.read<DataEntryBloc>();
    final state = bloc.state;
    // A reload replaces every cell — don't wipe unsaved edits.
    if (state is DataEntryLoaded && state.hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save your changes before reloading.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    bloc.add(DataEntryLoad(
      dataSetId: widget.dataSetId,
      orgUnitId: widget.orgUnitId,
      period: widget.period,
      sectionId: widget.sectionId,
    ));
  }

  // ── FAB tapped — save first ───────────────────────────────
  Future<void> _onSaveTapped() async {
    setState(() => _isSaving = true);

    final bloc = context.read<DataEntryBloc>();

    try {
      // Save data values via use case directly
      final state = bloc.state;
      if (state is DataEntryLoaded) {
        // Only the loaded form's values — with a single section
        // open the map also holds the other sections' existing
        // values, which must not be re-posted.
        final formElementIds = state.dataElements.map((e) => e.id).toSet();
        await bloc.repository.saveDataValues(
          dataValues: state.dataValues.values
              .where((v) => formElementIds.contains(v.dataElementId))
              .toList(),
          dataSetId: widget.dataSetId,
          orgUnitId: widget.orgUnitId,
          period: widget.period,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      // Show complete dialog
      await _showCompleteDialog();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Show complete bottom sheet ─────────────────────────────
  Future<void> _showCompleteDialog() async {
    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────
            Text(
              'Everything looks good',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // ── Message ────────────────────────────
            Text(
              'Do you also want to complete the data set ?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.spaceXL),

            // ── Buttons ────────────────────────────
            Row(
              children: [
                // Not now
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Not now',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.spaceMD),

                // Complete
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Complete',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // User chose Complete
      setState(() => _isCompleting = true);
      try {
        await context.read<DataEntryBloc>().repository.completeDataSet(
              dataSetId: widget.dataSetId,
              orgUnitId: widget.orgUnitId,
              period: widget.period,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data set completed successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, {
            'saved': true,
            'completed': true,
            'period': widget.period,
            'orgUnitName': widget.orgUnitName,
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCompleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // User chose Not now — go back with saved result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, {
          'saved': true,
          'completed': false,
          'period': widget.period,
          'orgUnitName': widget.orgUnitName,
        });
      }
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
        title: Text(
          widget.sectionName ?? widget.dataSetName,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: 'Reload values',
            onPressed: _onSyncTapped,
          ),
          const SizedBox(width: AppDimensions.spaceXS),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sub header ────────────────────────────
          _SubHeader(
            period: widget.period,
            orgUnitName: widget.orgUnitName,
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Table ─────────────────────────────────
          Expanded(
            child: BlocBuilder<DataEntryBloc, DataEntryState>(
              builder: (context, state) {
                if (state is DataEntryLoading) {
                  return const AppLoader(message: 'Loading form...');
                }
                if (state is DataEntryError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<DataEntryBloc>().add(
                          DataEntryLoad(
                            dataSetId: widget.dataSetId,
                            orgUnitId: widget.orgUnitId,
                            period: widget.period,
                            sectionId: widget.sectionId,
                          ),
                        ),
                  );
                }
                if (state is DataEntryLoaded) {
                  return DataEntryTable(
                    dataElements: state.dataElements,
                    dataValues: state.dataValues,
                    orgUnitId: widget.orgUnitId,
                    period: widget.period,
                  );
                }
                // Initial state (load event not processed yet) —
                // keep the spinner up instead of a blank page.
                return const AppLoader(message: 'Loading form...');
              },
            ),
          ),
        ],
      ),

      // ── Save FAB ──────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: (_isSaving || _isCompleting) ? null : _onSaveTapped,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: (_isSaving || _isCompleting)
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: AppDimensions.iconXL,
              ),
      ),
    );
  }
}

// ── Sub Header ─────────────────────────────────────────────────
class _SubHeader extends StatelessWidget {
  final String period;
  final String orgUnitName;
  const _SubHeader({required this.period, required this.orgUnitName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Text(
            EthiopianCalendar.formatPeriodId(period),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXL),
          Expanded(
            child: Text(
              orgUnitName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────
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
            const Icon(Icons.error_outline_rounded,
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            const Text('Could not load form',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(message,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
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

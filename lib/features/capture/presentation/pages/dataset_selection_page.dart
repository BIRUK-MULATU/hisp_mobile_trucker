import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/sync/manual_sync.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import '../../../../shared/widgets/sync_snackbar.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/entities/report_instance_entity.dart';
import '../../domain/usecases/get_org_unit_datasets_usecase.dart';
import '../widgets/dataset_card.dart';
import 'section_selection_page.dart';

/// Second step of the Capture workflow, with two views behind a
/// toggle: the datasets assigned to the selected organisation unit
/// (Select Dataset), and every report the user has worked on —
/// completed or incomplete drafts — across ALL org units (Report
/// Period).
enum _PageMode { datasets, reports }

class DatasetSelectionPage extends StatefulWidget {
  final String orgUnitId;
  final String orgUnitName;

  const DatasetSelectionPage({
    super.key,
    required this.orgUnitId,
    required this.orgUnitName,
  });

  @override
  State<DatasetSelectionPage> createState() => _DatasetSelectionPageState();
}

class _DatasetSelectionPageState extends State<DatasetSelectionPage> {
  late final CaptureRepositoryImpl _repository;
  late final GetOrgUnitDataSetsUseCase _getDataSets;

  _PageMode _mode = _PageMode.datasets;

  List<DataSetEntity>? _dataSets;
  String? _error;

  List<ReportInstanceEntity>? _reports;
  String? _reportsError;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _repository = CaptureRepositoryImpl();
    _getDataSets = GetOrgUnitDataSetsUseCase(_repository);
    _load();
    _loadReports();
  }

  Future<void> _load() async {
    setState(() {
      _dataSets = null;
      _error = null;
    });
    try {
      final dataSets = await _getDataSets.call(orgUnitId: widget.orgUnitId);
      if (mounted) setState(() => _dataSets = dataSets);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _reports = null;
      _reportsError = null;
    });
    try {
      final reports = await _repository.getUserReports();
      if (mounted) setState(() => _reports = reports);
    } catch (e) {
      if (mounted) {
        setState(
            () => _reportsError = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Same manual sync as the home app bar: push pending work, then
  /// reload both views so the cards' chips tell the new truth.
  Future<void> _onSyncTapped() async {
    if (_isSyncing) return;
    if (!AppSession.instance.isLoggedIn) return;
    final result = await runManualSync(
      onPushStart: () => setState(() => _isSyncing = true),
    );
    if (!mounted) return;
    setState(() => _isSyncing = false);
    showSyncResultSnackBar(context, result);
    if (result.pushedAnything) {
      await _loadReports();
      if (mounted) await _load();
    }
  }

  /// Straight into the whole-dataset form — a report already carries
  /// its dataset, period and org unit, so nothing is left to pick.
  Future<void> _openReport(ReportInstanceEntity report) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataEntryPage(
          dataSetId: report.dataSetId,
          dataSetName: report.dataSetName,
          orgUnitId: report.orgUnitId,
          orgUnitName: report.orgUnitName,
          period: report.periodId,
          periodType: report.periodType,
        ),
      ),
    );
    // Back from the form: drafts may have been completed (or new
    // ones saved) — reload both views.
    if (mounted) {
      await _loadReports();
      if (mounted) await _load();
    }
  }

  Future<void> _openDataSet(DataSetEntity dataSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionSelectionPage(
          dataSetId: dataSet.id,
          dataSetName: dataSet.name,
          periodType: dataSet.periodType,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
        ),
      ),
    );
    // Back from the form: values may have been saved (or pushed) —
    // reload so the synced/unsync chips tell the truth.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ConnectivityIndicator(),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      semanticsLabel: 'Syncing',
                    ),
                  )
                : const Icon(
                    Icons.sync_rounded,
                    color: Colors.white,
                    size: AppDimensions.iconLG,
                  ),
            onPressed: _isSyncing ? null : _onSyncTapped,
            tooltip: 'Sync all',
          ),
          const SizedBox(width: AppDimensions.spaceXS),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mode == _PageMode.datasets ? 'Select Dataset' : 'Report Period',
              style: AppTextStyles.appBarTitle,
            ),
            Text(
              // Reports span every org unit the user captured at.
              _mode == _PageMode.datasets
                  ? widget.orgUnitName
                  : 'All organisation units',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ResponsiveContent(
            maxWidth: AppBreakpoints.formMaxWidth,
            child: SegmentedToggle(
              items: const [
                SegmentedToggleItem(
                  label: 'Select Dataset',
                  icon: Icons.folder_rounded,
                ),
                SegmentedToggleItem(
                  label: 'Report Period',
                  icon: Icons.event_note_rounded,
                ),
              ],
              index: _mode.index,
              onChanged: (i) => setState(() => _mode = _PageMode.values[i]),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _mode == _PageMode.datasets
                ? _buildDatasetsBody()
                : _buildReportsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsBody() {
    if (_reportsError != null) {
      return _ErrorView(message: _reportsError!, onRetry: _loadReports);
    }
    final reports = _reports;
    if (reports == null) {
      return const AppLoader(message: 'Loading reports...');
    }
    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
              SizedBox(height: AppDimensions.spaceLG),
              Text('No reports yet', style: AppTextStyles.headingSmall),
              SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Reports you save as drafts or complete will show '
                'up here, across all your organisation units.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReports,
      child: ResponsiveContent(
        maxWidth: 1000,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _ReportCard(
              report: report,
              onTap: () => _openReport(report),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDatasetsBody() {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final dataSets = _dataSets;
    if (dataSets == null) {
      return const AppLoader(message: 'Loading datasets...');
    }
    if (dataSets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('No datasets available',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'No datasets are assigned to '
                '${widget.orgUnitName}.\nPick a different '
                'organisation unit or contact your administrator.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      // A width-capped grid: one column on phones, two on tablets,
      // never stretching cards across a whole desktop window.
      child: ResponsiveContent(
        maxWidth: 1000,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            // Tall enough for a 2-line title + chips row plus the
            // card's own margin/padding (a 108 extent overflowed).
            mainAxisExtent: 128,
          ),
          itemCount: dataSets.length,
          itemBuilder: (context, index) {
            final dataSet = dataSets[index];
            return DataSetCard(
              dataSet: dataSet,
              onTap: () => _openDataSet(dataSet),
            );
          },
        ),
      ),
    );
  }
}

// ── Report card ────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final ReportInstanceEntity report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final completed = report.status == ReportStatus.completed;
    final statusColor = completed ? AppColors.success : AppColors.warning;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space),
          child: Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.edit_note_rounded,
                color: statusColor,
                size: AppDimensions.iconXL,
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.dataSetName,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      '${report.periodLabel} · ${report.orgUnitName}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ReportChip(
                    label: completed ? 'Completed' : 'Incomplete',
                    color: statusColor,
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  _ReportChip(
                    label: report.synced ? 'Synced' : 'Unsynced',
                    icon: report.synced
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_upload_rounded,
                    color: report.synced
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _ReportChip({required this.label, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppDimensions.spaceXS),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            const Text('Could not load datasets',
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

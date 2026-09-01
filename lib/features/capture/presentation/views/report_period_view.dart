import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/report_instance_entity.dart';

/// Home's default Capture-mode body: every report the user has
/// worked on — completed or incomplete drafts — across ALL
/// organisation units, newest first. Starting a new report is the
/// FAB's job (see HomePage), not this list's.
class ReportPeriodView extends StatefulWidget {
  /// App-bar search — matches against dataset name or org unit name.
  final String? searchQuery;

  /// Filter-panel ORG. UNIT text.
  final String? orgUnitQuery;

  /// Filter-panel SYNC selections ('Synced' / 'UnSynced' / 'Sync Error').
  final Set<String> syncFilters;

  /// Filter-panel DATE window over each report's last local change.
  final DateTimeRange? dateRange;

  const ReportPeriodView({
    super.key,
    this.searchQuery,
    this.orgUnitQuery,
    this.syncFilters = const {},
    this.dateRange,
  });

  @override
  State<ReportPeriodView> createState() => _ReportPeriodViewState();
}

class _ReportPeriodViewState extends State<ReportPeriodView> {
  final _repository = CaptureRepositoryImpl();
  List<ReportInstanceEntity>? _reports;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _reports = null;
      _error = null;
    });
    try {
      final reports = await _repository.getUserReports();
      if (mounted) setState(() => _reports = reports);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  String get _query => widget.searchQuery?.toLowerCase() ?? '';
  String get _orgUnitQuery => widget.orgUnitQuery?.toLowerCase() ?? '';

  List<ReportInstanceEntity> _applyFilters(List<ReportInstanceEntity> all) {
    return all.where((r) {
      final name = r.dataSetName.toLowerCase();
      final org = r.orgUnitName.toLowerCase();
      if (_query.isNotEmpty && !name.contains(_query) && !org.contains(_query)) {
        return false;
      }
      if (_orgUnitQuery.isNotEmpty && !org.contains(_orgUnitQuery)) {
        return false;
      }
      if (widget.syncFilters.isNotEmpty) {
        final matches = widget.syncFilters.any((label) {
          switch (label) {
            case 'Synced':
              return r.synced;
            case 'Sync Error':
              return r.syncError != null;
            case 'UnSynced':
              return !r.synced && r.syncError == null;
            default:
              return false;
          }
        });
        if (!matches) return false;
      }
      final range = widget.dateRange;
      if (range != null &&
          (r.lastModified.isBefore(range.start) ||
              !r.lastModified.isBefore(range.end))) {
        return false;
      }
      return true;
    }).toList();
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
          isDiseaseRegistration: report.isDiseaseRegistration,
          attributeOptionComboUid: report.attributeOptionComboUid,
        ),
      ),
    );
    // Back from the form: the report may have changed status — reload.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final all = _reports;
    if (all == null) {
      return const AppLoader(message: 'Loading reports...');
    }
    if (all.isEmpty) {
      return const _EmptyView(
        icon: Icons.event_note_rounded,
        title: 'No reports yet',
        message: 'Reports you save as drafts or complete will show up '
            'here, across all your organisation units.\n'
            'Tap the + button to start one.',
      );
    }
    final reports = _applyFilters(all);
    if (reports.isEmpty) {
      return const _EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No results',
        message: 'No reports match the current search or filters.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppDimensions.spaceMD,
          // Extra room so the last card never sits under the FAB.
          bottom: AppDimensions.spaceGiant + AppDimensions.spaceXXL,
        ),
        itemCount: reports.length,
        itemBuilder: (context, index) => _ReportCard(
          report: reports[index],
          onTap: () => _openReport(reports[index]),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
                      report.attributeOptionComboLabel == null
                          ? '${report.periodLabel} · ${report.orgUnitName}'
                          : '${report.periodLabel} · ${report.orgUnitName} '
                              '· ${report.attributeOptionComboLabel}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (report.syncError != null) ...[
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        report.syncError!,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.error),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                    color: report.synced ? AppColors.primary : AppColors.error,
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
            const Text('Could not load reports',
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

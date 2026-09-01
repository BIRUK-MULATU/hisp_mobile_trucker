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

  /// Fired when a sync dashboard card is tapped — same shape as the
  /// filter panel's own sync selection, so the parent can keep both
  /// in sync from one piece of state (see HomePage).
  final ValueChanged<Set<String>>? onSyncFilterChanged;

  const ReportPeriodView({
    super.key,
    this.searchQuery,
    this.orgUnitQuery,
    this.syncFilters = const {},
    this.dateRange,
    this.onSyncFilterChanged,
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

  static bool _matchesSync(ReportInstanceEntity r, String label) {
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
  }

  bool _matchesScope(ReportInstanceEntity r) {
    final name = r.dataSetName.toLowerCase();
    final org = r.orgUnitName.toLowerCase();
    if (_query.isNotEmpty && !name.contains(_query) && !org.contains(_query)) {
      return false;
    }
    if (_orgUnitQuery.isNotEmpty && !org.contains(_orgUnitQuery)) {
      return false;
    }
    final range = widget.dateRange;
    if (range != null &&
        (r.lastModified.isBefore(range.start) ||
            !r.lastModified.isBefore(range.end))) {
      return false;
    }
    return true;
  }

  /// Search/org-unit/date only — the pool the sync dashboard's counts
  /// are drawn from, so every card keeps its own true number no
  /// matter which (if any) sync group is currently selected.
  List<ReportInstanceEntity> _applyScopeFilters(
          List<ReportInstanceEntity> all) =>
      all.where(_matchesScope).toList();

  /// The scoped pool narrowed by the active sync filter — what the
  /// list itself shows.
  List<ReportInstanceEntity> _applySyncFilter(
      List<ReportInstanceEntity> scoped) {
    if (widget.syncFilters.isEmpty) return scoped;
    return scoped
        .where((r) => widget.syncFilters.any((label) => _matchesSync(r, label)))
        .toList();
  }

  /// Dashboard card tap: drills down into that single group, or — if
  /// it's already the only thing selected — clears back to "all".
  void _onSyncCardTapped(String label) {
    final current = widget.syncFilters;
    final next = current.length == 1 && current.contains(label)
        ? const <String>{}
        : {label};
    widget.onSyncFilterChanged?.call(next);
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
    final scoped = _applyScopeFilters(all);
    final counts = _SyncCounts.fromReports(scoped);
    final reports = _applySyncFilter(scoped);

    return Column(
      children: [
        _SyncSummaryBar(
          counts: counts,
          selected: widget.syncFilters,
          onSelect: _onSyncCardTapped,
        ),
        Expanded(
          child: reports.isEmpty
              ? const _EmptyView(
                  icon: Icons.search_off_rounded,
                  title: 'No results',
                  message: 'No reports match the current search or filters.',
                )
              : RefreshIndicator(
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
                ),
        ),
      ],
    );
  }
}

// ── Sync dashboard ─────────────────────────────────────────────
class _SyncCounts {
  final int synced;
  final int unsynced;
  final int error;

  const _SyncCounts({
    required this.synced,
    required this.unsynced,
    required this.error,
  });

  /// Buckets are mutually exclusive by construction — a completion
  /// row only carries a sync error once it's no longer counted as
  /// synced (see ReportInstanceEntity/_ReportFacts.synced) — so every
  /// report lands in exactly one bucket and the three counts always
  /// sum to `reports.length`.
  factory _SyncCounts.fromReports(List<ReportInstanceEntity> reports) {
    var synced = 0, unsynced = 0, error = 0;
    for (final r in reports) {
      if (r.syncError != null) {
        error++;
      } else if (r.synced) {
        synced++;
      } else {
        unsynced++;
      }
    }
    return _SyncCounts(synced: synced, unsynced: unsynced, error: error);
  }
}

/// Three tappable stat cards — Synced / Unsynced / Sync Error — each
/// showing how many of the currently scoped reports fall into that
/// group. Tapping one drills the list below into just that group
/// (see ReportPeriodView._onSyncCardTapped); tapping the active one
/// again clears back to "all".
class _SyncSummaryBar extends StatelessWidget {
  final _SyncCounts counts;
  final Set<String> selected;
  final ValueChanged<String> onSelect;

  const _SyncSummaryBar({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space,
        AppDimensions.spaceMD,
        AppDimensions.space,
        AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SyncStatCard(
              label: 'Synced',
              count: counts.synced,
              icon: Icons.cloud_done_rounded,
              color: AppColors.success,
              selected: selected.contains('Synced'),
              onTap: () => onSelect('Synced'),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: _SyncStatCard(
              label: 'Unsynced',
              count: counts.unsynced,
              icon: Icons.cloud_upload_rounded,
              color: AppColors.textDisabled,
              selected: selected.contains('UnSynced'),
              onTap: () => onSelect('UnSynced'),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: _SyncStatCard(
              label: 'Sync Error',
              count: counts.error,
              icon: Icons.error_rounded,
              color: AppColors.error,
              selected: selected.contains('Sync Error'),
              onTap: () => onSelect('Sync Error'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SyncStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceSM,
          vertical: AppDimensions.spaceMD,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppDimensions.iconMD),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              '$count',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            Icon(icon,
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
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

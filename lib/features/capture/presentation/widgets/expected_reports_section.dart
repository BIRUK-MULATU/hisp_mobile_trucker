import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/notifications/report_reminder_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/expected_report_entity.dart';
import '../pages/period_selection_page.dart';

/// The "reports you still owe" band at the top of the Capture tab.
/// Collapsed to a one-line summary; tap to expand the list of
/// outstanding dataset/period/facility combinations, most urgent
/// first. Hidden entirely when nothing is outstanding.
class ExpectedReportsSection extends StatefulWidget {
  /// Bumped by the parent to force a reload (e.g. after a sync).
  final int reloadTick;

  /// Called after the user returns from a form opened here, so the
  /// parent can refresh its own "reports worked on" list too.
  final VoidCallback? onReturned;

  /// Emitted whenever the outstanding set is recomputed —
  /// `(total, overdue)` — so a parent (e.g. the drawer) can show a
  /// count without loading the list itself.
  final void Function(int total, int overdue)? onCounts;

  /// When true, the list starts expanded (e.g. arrived here from the
  /// drawer's "Reports to fill" item).
  final bool startExpanded;

  const ExpectedReportsSection({
    super.key,
    this.reloadTick = 0,
    this.onReturned,
    this.onCounts,
    this.startExpanded = false,
  });

  @override
  State<ExpectedReportsSection> createState() => _ExpectedReportsSectionState();
}

class _ExpectedReportsSectionState extends State<ExpectedReportsSection> {
  final _repository = CaptureRepositoryImpl();
  List<ExpectedReportEntity>? _reports;
  late bool _expanded = widget.startExpanded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ExpectedReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick) _load();
  }

  Future<void> _load() async {
    try {
      final reports = await _repository.getExpectedReports();
      if (mounted) setState(() => _reports = reports);
      _emitCounts(reports);
      // Keep the on-device deadline reminders in step with what's
      // actually outstanding — recomputed here, so they never drift.
      unawaited(ReportReminderService.instance.reschedule(reports));
    } catch (_) {
      // Non-fatal — the band just stays hidden.
      if (mounted) setState(() => _reports = const []);
      _emitCounts(const []);
    }
  }

  void _emitCounts(List<ExpectedReportEntity> reports) {
    widget.onCounts?.call(
      reports.length,
      reports.where((r) => r.urgency == ReportUrgency.overdue).length,
    );
  }

  Future<void> _open(ExpectedReportEntity r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => r.needsComboPick
            ? PeriodSelectionPage(
                dataSetId: r.dataSetId,
                dataSetName: r.dataSetName,
                periodType: r.periodType,
                orgUnitId: r.orgUnitId,
                orgUnitName: r.orgUnitName,
                isDiseaseRegistration: r.isDiseaseRegistration,
              )
            : DataEntryPage(
                dataSetId: r.dataSetId,
                dataSetName: r.dataSetName,
                orgUnitId: r.orgUnitId,
                orgUnitName: r.orgUnitName,
                period: r.periodId,
                periodType: r.periodType,
                isDiseaseRegistration: r.isDiseaseRegistration,
              ),
      ),
    );
    if (!mounted) return;
    await _load();
    widget.onReturned?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports;
    if (reports == null || reports.isEmpty) return const SizedBox.shrink();

    final overdue = reports.where((r) => r.urgency == ReportUrgency.overdue);
    final accent =
        overdue.isNotEmpty ? AppColors.error : AppColors.warning;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            color: accent.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space,
              vertical: AppDimensions.spaceMD,
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_late_rounded,
                    color: accent, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: Text(
                    _summary(reports.length, overdue.length),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceXS),
              children: [
                for (final r in reports)
                  _ExpectedCard(report: r, onTap: () => _open(r)),
              ],
            ),
          ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  static String _summary(int total, int overdue) {
    final base = '$total report${total == 1 ? '' : 's'} to fill';
    return overdue == 0 ? base : '$base · $overdue overdue';
  }
}

class _ExpectedCard extends StatelessWidget {
  final ExpectedReportEntity report;
  final VoidCallback onTap;

  const _ExpectedCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, dueText) = _due(report);
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: report.urgency == ReportUrgency.overdue
              ? AppColors.error
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space),
          child: Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  color: color, size: AppDimensions.iconXL),
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
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      dueText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              if (report.localStarted)
                const _Pill(label: 'Started', color: AppColors.primary)
              else
                const _Pill(
                    label: 'Not started', color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDay(DateTime d) =>
      '${d.day} ${_months[d.month - 1]}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  (Color, String) _due(ExpectedReportEntity r) {
    final lock = r.lockDate;
    switch (r.urgency) {
      case ReportUrgency.overdue:
        return (
          AppColors.error,
          lock == null
              ? 'Overdue'
              : 'Overdue — locks ${_fmtDay(lock)}',
        );
      case ReportUrgency.dueSoon:
        return (
          AppColors.warning,
          lock == null
              ? 'Due soon'
              : 'Due soon — locks ${_fmtDay(lock)}',
        );
      case ReportUrgency.open:
        return (
          AppColors.textSecondary,
          lock == null ? 'Open' : 'Locks ${_fmtDay(lock)}',
        );
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

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
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

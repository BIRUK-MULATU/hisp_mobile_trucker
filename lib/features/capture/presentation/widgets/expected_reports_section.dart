import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/notifications/report_reminder_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/expected_report_entity.dart';
import '../pages/period_selection_page.dart';

/// The "reports you still owe" list on the Capture tab. Owns loading,
/// count reporting and reminder scheduling; renders the outstanding
/// dataset/period/facility combinations (most urgent first) only when
/// the parent flips [visible] — the "Reports to fill" dashboard card
/// drives that. Hidden entirely when nothing is outstanding.
class ExpectedReportsSection extends StatefulWidget {
  /// Bumped by the parent to force a reload (e.g. after a sync).
  final int reloadTick;

  /// Called after the user returns from a form opened here, so the
  /// parent can refresh its own "reports worked on" list too.
  final VoidCallback? onReturned;

  /// Emitted whenever the outstanding set is recomputed —
  /// `(total, overdue)` — so a parent can show the count on its
  /// "Reports to fill" dashboard card without loading the list itself.
  final void Function(int total, int overdue)? onCounts;

  /// When true, the outstanding list renders in place of the report
  /// list (driven by the "Reports to fill" dashboard card).
  final bool visible;

  /// Overrides the repository the section loads with — tests inject a
  /// session-backed fake so the widget never needs a live login.
  final CaptureRepositoryImpl? repository;

  const ExpectedReportsSection({
    super.key,
    this.reloadTick = 0,
    this.onReturned,
    this.onCounts,
    this.visible = false,
    this.repository,
  });

  @override
  State<ExpectedReportsSection> createState() => _ExpectedReportsSectionState();
}

class _ExpectedReportsSectionState extends State<ExpectedReportsSection> {
  late final _repository = widget.repository ?? CaptureRepositoryImpl();
  List<ExpectedReportEntity>? _reports;

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
    // Local-first: getExpectedReports is network-free, so the list and
    // its count paint in a few milliseconds. Online freshness happens
    // separately, in the background (see _reconcileAndReload) — the
    // user should never wait on the server just to SEE what they owe.
    // Only the truly-first load reports "loading" to a parent; a
    // refresh that already has data must not knock the list out from
    // under the user. (The "wait a moment" message itself is rendered
    // right here in build, whenever the card is open but no data is in
    // yet — so opening always feels instant.)
    List<ExpectedReportEntity> reports;
    try {
      reports = await _repository.getExpectedReports();
    } catch (_) {
      reports = const [];
    }
    if (!mounted) return;
    setState(() => _reports = reports);
    _emitCounts(reports);
    // Keep the on-device deadline reminders in step with what's
    // actually outstanding — recomputed here, so they never drift.
    unawaited(ReportReminderService.instance.reschedule(reports));
    unawaited(_reconcileAndReload());
  }

  /// Fired without awaiting after every local render. Pulls the
  /// server's completion state (a report finished on the web / another
  /// device should stop counting as owed) and reloads only when the
  /// reconcile actually changed something — so the network is never in
  /// the way of the first paint, but the list still self-corrects soon
  /// after.
  Future<void> _reconcileAndReload() async {
    final applied = await _repository.reconcileExpectedReports();
    if (applied > 0 && mounted) await _load();
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
    if (!widget.visible) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final reports = _reports;

    // Wait message for the instant between opening the card and the
    // first (local, millisecond-fast) load finishing.
    if (reports == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoader(message: 'Checking reports to fill…'),
      );
    }
    if (reports.isEmpty) {
      // Growable but honest: nothing outstanding across every assigned
      // dataset x open period for the user's facilities.
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.task_alt_rounded,
          title: 'Nothing to fill',
          message: 'Every report assigned to your organisation units is '
              'up to date.',
        ),
      );
    }

    // A virtualized, lazily-built sliver of cards — exactly like the
    // report list the sync cards filter — so scrolling stays smooth
    // however many reports are owing. No cap, no shrink-wrap:
    // a capped box reads as a "dropdown", which the dashboards don't do.
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spaceMD,
        // Extra room so the last card never sits under the FAB.
        bottom: AppDimensions.spaceGiant + AppDimensions.spaceXXL,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ExpectedCard(
            report: reports[index],
            onTap: () => _open(reports[index]),
          ),
          childCount: reports.length,
        ),
      ),
    );
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
              : 'Overdue — locked ${_fmtDay(lock)}',
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

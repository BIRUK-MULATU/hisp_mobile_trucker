import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// A dashboard entry shown in the Visualization tab.
class DashboardItem {
  final String id;
  final String name;

  const DashboardItem({required this.id, required this.name});
}

/// The Visualization side of the home toggle. Real dashboards are a
/// future task — the list is empty until then, but the search wiring
/// (home app bar → [searchQuery] → name filter) is already in place
/// so dashboards become searchable the moment they exist.
class VisualizationView extends StatelessWidget {
  /// Null while search is closed; otherwise the dashboard list is
  /// filtered to names containing the query (case-insensitive).
  final String? searchQuery;

  const VisualizationView({super.key, this.searchQuery});

  /// Replaced with real data once dashboards are implemented.
  static const List<DashboardItem> _dashboards = [];

  @override
  Widget build(BuildContext context) {
    final query = searchQuery?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      if (_dashboards.isEmpty) return const _ComingSoonPlaceholder();
      return const _DashboardList(dashboards: _dashboards);
    }
    final matches = _dashboards
        .where((d) => d.name.toLowerCase().contains(query))
        .toList();
    if (matches.isEmpty) {
      return _NoResultsPlaceholder(query: searchQuery!.trim());
    }
    return _DashboardList(dashboards: matches);
  }
}

class _DashboardList extends StatelessWidget {
  final List<DashboardItem> dashboards;

  const _DashboardList({required this.dashboards});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.space),
      itemCount: dashboards.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spaceSM),
      itemBuilder: (context, index) {
        final dashboard = dashboards[index];
        return ListTile(
          leading: const Icon(
            Icons.insights_rounded,
            color: AppColors.primary,
          ),
          title: Text(dashboard.name, style: AppTextStyles.bodyLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: const BorderSide(color: AppColors.divider),
          ),
        );
      },
    );
  }
}

class _NoResultsPlaceholder extends StatelessWidget {
  final String query;

  const _NoResultsPlaceholder({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.space),
            Text(
              'No dashboards match "$query"',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonPlaceholder extends StatelessWidget {
  const _ComingSoonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            const Text(
              'Visualizations coming soon',
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              'Dashboards and charts for your organisation unit '
              'will appear here.\nSwitch to Capture to start '
              'entering data.',
              style: AppTextStyles.bodySmall.copyWith(
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

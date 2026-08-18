import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/chart_repository_impl.dart';
import '../../domain/entities/dashboard_ref.dart';
import '../pages/dashboard_detail_page.dart';
import '../widgets/offline_cache_banner.dart';

/// The Dashboards tab: every dashboard on the DHIS2 server, mirroring
/// the WebApp's Dashboard app — tapping one drills into its
/// visualization items (see [DashboardDetailPage]). The last
/// successful list is cached, so this still shows something while
/// offline (see [ChartRepositoryImpl.loadDashboards]).
class DashboardsListView extends StatefulWidget {
  final String? searchQuery;

  const DashboardsListView({super.key, this.searchQuery});

  @override
  State<DashboardsListView> createState() => DashboardsListViewState();
}

class DashboardsListViewState extends State<DashboardsListView> {
  final _repository = ChartRepositoryImpl();

  List<DashboardRef>? _dashboards;
  String? _error;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    reload();
    // Reconnecting refreshes a cached list with live data automatically.
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (_isFromCache && (ConnectivityService.instance.online ?? false)) {
      reload();
    }
  }

  Future<void> reload() async {
    setState(() => _error = null);
    try {
      final result = await _repository.loadDashboards();
      if (mounted) {
        setState(() {
          _dashboards = result.dashboards;
          _isFromCache = result.isFromCache;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  List<DashboardRef> get _filtered {
    final q = widget.searchQuery?.trim().toLowerCase() ?? '';
    final all = _dashboards ?? const <DashboardRef>[];
    if (q.isEmpty) return all;
    return [
      for (final d in all)
        if (d.name.toLowerCase().contains(q)) d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isFromCache && _error == null) const OfflineCacheBanner(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_error != null) {
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
              Text(_error!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceXL),
              ElevatedButton.icon(
                onPressed: reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_dashboards == null) {
      return const AppLoader(message: 'Loading dashboards...');
    }
    final dashboards = _filtered;
    if (dashboards.isEmpty) {
      final query = widget.searchQuery?.trim() ?? '';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                query.isEmpty
                    ? Icons.space_dashboard_outlined
                    : Icons.search_off_rounded,
                size: AppDimensions.iconHuge,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Text(query.isEmpty ? 'No dashboards' : 'No results',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center),
              if (query.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Text('No dashboards match "$query".',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: reload,
      child: ResponsiveContent(
        maxWidth: 1000,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space,
            vertical: AppDimensions.spaceMD,
          ),
          itemCount: dashboards.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.spaceSM),
          itemBuilder: (context, index) {
            final dashboard = dashboards[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardDetailPage(dashboard: dashboard),
                  ),
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space,
                    vertical: AppDimensions.spaceMD,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.space_dashboard_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Text(
                          dashboard.name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

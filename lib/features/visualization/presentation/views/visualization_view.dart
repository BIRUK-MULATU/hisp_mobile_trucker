import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/visualization_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../pages/dashboard_page.dart';

/// The Visualization side of the home toggle: the user's DHIS2
/// dashboards, fetched from /api/dashboards. Tapping one opens its
/// charts (rendered natively from the analytics API). Online-only
/// for now — offline caching waits on the DB migration strategy.
class VisualizationView extends StatefulWidget {
  /// Null while search is closed; otherwise the dashboard list is
  /// filtered to names containing the query (case-insensitive).
  final String? searchQuery;

  const VisualizationView({super.key, this.searchQuery});

  @override
  State<VisualizationView> createState() => _VisualizationViewState();
}

class _VisualizationViewState extends State<VisualizationView> {
  final _repository = VisualizationRepositoryImpl();

  List<DashboardEntity>? _dashboards;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _dashboards = null;
      _error = null;
      _offline = false;
    });
    await ConnectivityService.instance.checkNow();
    if (!mounted) return;
    if (!(ConnectivityService.instance.online ?? false)) {
      setState(() => _offline = true);
      return;
    }
    try {
      final dashboards = await _repository.getDashboards();
      if (mounted) setState(() => _dashboards = dashboards);
    } on DioException catch (e) {
      // Some gateways (staging) answer 404/403 for endpoints the
      // account may not use — say so instead of dumping the Dio error.
      final code = e.response?.statusCode;
      if (mounted) {
        setState(() => _error = (code == 404 || code == 403)
            ? 'Dashboards are not available on this server for your '
                'account (the endpoint is blocked or a permission is '
                'missing). Data capture is not affected. Please contact '
                'your administrator.'
            : 'The server could not be reached'
                '${code == null ? '' : ' (error $code)'}. Try again in a '
                'moment.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  List<DashboardEntity> get _filtered {
    final query = widget.searchQuery?.trim().toLowerCase() ?? '';
    final all = _dashboards ?? const [];
    if (query.isEmpty) return all;
    return [
      for (final d in all)
        if (d.name.toLowerCase().contains(query)) d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'You are offline',
        body: 'Dashboards need a connection to the server. '
            'They will load when you are back online.',
        onRetry: _load,
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: 'Could not load dashboards',
        body: _error!,
        onRetry: _load,
      );
    }
    if (_dashboards == null) {
      return const AppLoader(message: 'Loading dashboards...');
    }
    final dashboards = _filtered;
    if (dashboards.isEmpty) {
      final query = widget.searchQuery?.trim() ?? '';
      return _Message(
        icon: query.isEmpty
            ? Icons.insights_rounded
            : Icons.search_off_rounded,
        title: query.isEmpty ? 'No dashboards' : 'No results',
        body: query.isEmpty
            ? 'No dashboards are shared with your account. '
                'Dashboards are created on the DHIS2 web portal.'
            : 'No dashboards match "$query".',
        onRetry: query.isEmpty ? _load : null,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
        itemCount: dashboards.length,
        itemBuilder: (context, index) {
          final dashboard = dashboards[index];
          return _DashboardCard(
            dashboard: dashboard,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(dashboard: dashboard),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final DashboardEntity dashboard;
  final VoidCallback onTap;

  const _DashboardCard({required this.dashboard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final charts = dashboard.visualizations.length;
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
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.name,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      charts == 0
                          ? 'No charts'
                          : '$charts ${charts == 1 ? 'chart' : 'charts'}'
                              '${dashboard.unsupportedItems > 0 ? ' · ${dashboard.unsupportedItems} unsupported' : ''}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
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
            Text(title,
                style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

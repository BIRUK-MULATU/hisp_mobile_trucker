import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/chart_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/dashboard_ref.dart';
import '../../domain/entities/remote_visualization.dart';
import '../widgets/dhis2_chart.dart';
import '../widgets/offline_cache_banner.dart';

/// Icon per DHIS2 visualization type — deliberately independent of
/// this app's own [ChartType] enum (chart_config.dart), which only
/// lists the types the in-app builder can CREATE. A server dashboard
/// may hold any DHIS2 visualization type (PIVOT_TABLE, SCATTER,
/// RADAR, YEAR_OVER_YEAR_*…), all of which this app fetches and
/// renders (via [Dhis2Chart]'s table fallback where there's no
/// native chart for the shape) — mapping them through [ChartType]
/// would silently relabel every one of those as a plain column icon.
IconData _iconForVisualizationType(String type) => switch (type.toUpperCase()) {
      'COLUMN' || 'STACKED_COLUMN' || 'YEAR_OVER_YEAR_COLUMN' =>
        Icons.bar_chart_rounded,
      'BAR' || 'STACKED_BAR' => Icons.notes_rounded,
      'LINE' || 'AREA' || 'STACKED_AREA' || 'YEAR_OVER_YEAR_LINE' =>
        Icons.show_chart_rounded,
      'PIE' => Icons.pie_chart_rounded,
      'SINGLE_VALUE' => Icons.looks_one_rounded,
      'GAUGE' => Icons.speed_rounded,
      'PIVOT_TABLE' => Icons.table_chart_outlined,
      'SCATTER' => Icons.scatter_plot_rounded,
      'RADAR' => Icons.radar_rounded,
      _ => Icons.insert_chart_outlined_rounded,
    };

/// One dashboard's visualization items, rendered inline — same as the
/// WebApp's Dashboard page: every item's title plus its actual chart,
/// stacked in one scrollable page. Each card loads its own analytics
/// query independently, so one slow or failing chart doesn't block
/// the rest. The item list itself is cached (see
/// [ChartRepositoryImpl.loadDashboardVisualizations]), and each
/// card's chart data caches too, so a previously-viewed dashboard
/// still renders offline.
class DashboardDetailPage extends StatefulWidget {
  final DashboardRef dashboard;

  const DashboardDetailPage({super.key, required this.dashboard});

  @override
  State<DashboardDetailPage> createState() => _DashboardDetailPageState();
}

class _DashboardDetailPageState extends State<DashboardDetailPage> {
  final _repository = ChartRepositoryImpl();

  List<RemoteVisualizationRef>? _items;
  String? _error;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (_isFromCache && (ConnectivityService.instance.online ?? false)) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final result =
          await _repository.loadDashboardVisualizations(widget.dashboard.id);
      if (mounted) {
        setState(() {
          _items = result.items;
          _isFromCache = result.isFromCache;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
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
          widget.dashboard.name,
          style: AppTextStyles.appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (_isFromCache && _error == null) const OfflineCacheBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
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
              Text(_error!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceXL),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items == null) {
      return const AppLoader(message: 'Loading dashboard...');
    }
    if (_items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_chart_outlined_rounded,
                  size: AppDimensions.iconHuge,
                  color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('No visualizations',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                "This dashboard has no chart items this app can render "
                "yet (maps aren't supported).",
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.5),
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
      child: ResponsiveContent(
        maxWidth: 1000,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.space),
          itemCount: _items!.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.spaceMD),
          itemBuilder: (context, index) => _DashboardChartCard(
            repository: _repository,
            ref: _items![index],
          ),
        ),
      ),
    );
  }
}

/// One visualization's title + chart, loaded independently of its
/// siblings so a slow or failing query only ever blocks its own card.
class _DashboardChartCard extends StatefulWidget {
  final ChartRepositoryImpl repository;
  final RemoteVisualizationRef ref;

  const _DashboardChartCard({required this.repository, required this.ref});

  @override
  State<_DashboardChartCard> createState() => _DashboardChartCardState();
}

class _DashboardChartCardState extends State<_DashboardChartCard> {
  AnalyticsData? _data;
  String? _error;
  bool _isFromCache = false;
  DateTime? _cachedAt;

  @override
  void initState() {
    super.initState();
    _load();
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (_isFromCache && (ConnectivityService.instance.online ?? false)) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
      _isFromCache = false;
      _cachedAt = null;
    });
    try {
      final result = await widget.repository.loadServerVisualization(widget.ref);
      if (mounted) {
        setState(() {
          _data = result.data;
          _isFromCache = result.isFromCache;
          _cachedAt = result.cachedAt;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForVisualizationType(widget.ref.type),
                    color: AppColors.primary, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: Text(
                    widget.ref.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_isFromCache && _error == null) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                child: OfflineCacheBanner(cachedAt: _cachedAt),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceMD),
            if (_error != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimensions.spaceLG),
                child: Center(
                  child: Column(
                    children: [
                      Text(_error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppDimensions.spaceSM),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_data == null)
              const SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              )
            else
              Dhis2Chart(data: _data!),
          ],
        ),
      ),
    );
  }
}

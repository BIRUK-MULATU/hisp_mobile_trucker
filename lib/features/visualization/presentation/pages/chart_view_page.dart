import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/local_visualization_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_config.dart';
import '../../domain/usecases/load_visualization_usecase.dart';
import '../widgets/dhis2_chart.dart';
import '../widgets/offline_cache_banner.dart';
import 'chart_edit_page.dart';

/// A saved chart, full page: reruns its analytics query on open so
/// the numbers are current, then renders it with the shared renderer.
/// The Edit action opens [ChartEditPage]; a successful edit pops this
/// page too (with `true`) since [config] is now stale.
class ChartViewPage extends StatefulWidget {
  final ChartConfig config;

  const ChartViewPage({super.key, required this.config});

  @override
  State<ChartViewPage> createState() => _ChartViewPageState();
}

class _ChartViewPageState extends State<ChartViewPage> {
  final _repository = LocalVisualizationRepositoryImpl();
  late final _loadVisualization = LoadVisualizationUseCase(_repository);

  AnalyticsData? _data;
  String? _error;
  bool _isFromCache = false;
  DateTime? _cachedAt;

  @override
  void initState() {
    super.initState();
    _load();
    // Reconnecting refreshes a cached chart with live data automatically
    // — no need for the user to pull-to-refresh once back online.
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
    await ConnectivityService.instance.checkNow();
    if (!mounted) return;
    final knownOffline = ConnectivityService.instance.online == false;
    try {
      final result = await _loadVisualization(widget.config,
          skipLiveAttempt: knownOffline);
      if (!mounted) return;
      setState(() {
        _data = result.data;
        _isFromCache = result.isFromCache;
        _cachedAt = result.cachedAt;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChartEditPage(config: widget.config)),
    );
    // The edit updated this chart's saved config — this page's copy is
    // now stale, so bubble the change up rather than trying to patch
    // it in place.
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.name,
                style: AppTextStyles.appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              config.summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _edit,
            tooltip: 'Edit chart',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isFromCache) OfflineCacheBanner(cachedAt: _cachedAt),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return _error != null
          ? Center(
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
            )
          : _data == null
              ? const AppLoader(message: 'Loading chart...')
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppDimensions.space),
                    children: [
                      ResponsiveContent(
                        child: Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMD),
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space),
                            child: Dhis2Chart(data: _data!),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
  }
}

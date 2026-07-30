import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/chart_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_config.dart';
import '../widgets/dhis2_chart.dart';

/// A saved chart, full page: reruns its analytics query on open so
/// the numbers are current, then renders it with the shared renderer.
class ChartViewPage extends StatefulWidget {
  final ChartConfig config;

  const ChartViewPage({super.key, required this.config});

  @override
  State<ChartViewPage> createState() => _ChartViewPageState();
}

class _ChartViewPageState extends State<ChartViewPage> {
  final _repository = ChartRepositoryImpl();

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
      final result = await _repository.loadChart(widget.config,
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
      ),
      body: Column(
        children: [
          if (_isFromCache) _CacheBanner(cachedAt: _cachedAt),
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

/// Tells the user they're looking at a snapshot, not live numbers —
/// shown whenever the live query failed (offline, timeout, server
/// error) and [ChartRepositoryImpl.loadChart] fell back to whatever
/// was cached from the last successful view of this chart.
class _CacheBanner extends StatelessWidget {
  const _CacheBanner({required this.cachedAt});

  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final when = cachedAt == null
        ? ''
        : ' from ${cachedAt!.toLocal().toString().substring(0, 16)}';
    return Container(
      width: double.infinity,
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: AppDimensions.iconSM, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              'Offline — showing cached data$when',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

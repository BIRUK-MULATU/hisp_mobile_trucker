import 'package:flutter/material.dart';

import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/chart_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/remote_visualization.dart';
import '../widgets/dhis2_chart.dart';

/// A visualization that lives on the DHIS2 server — built in the
/// WebApp, not this app. Always queried live via
/// [ChartRepositoryImpl.runServerVisualization]; nothing about it is
/// cached or stored on the device, and there is no delete action here
/// since the app doesn't own the object.
class RemoteChartViewPage extends StatefulWidget {
  final RemoteVisualizationRef ref;

  const RemoteChartViewPage({super.key, required this.ref});

  @override
  State<RemoteChartViewPage> createState() => _RemoteChartViewPageState();
}

class _RemoteChartViewPageState extends State<RemoteChartViewPage> {
  final _repository = ChartRepositoryImpl();

  AnalyticsData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final data = await _repository.runServerVisualization(widget.ref);
      if (!mounted) return;
      setState(() => _data = data);
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
          widget.ref.name,
          style: AppTextStyles.appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
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
    if (_data == null) {
      return const AppLoader(message: 'Loading chart...');
    }
    return RefreshIndicator(
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
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

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../data/repositories/visualization_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../widgets/dhis2_chart.dart';

/// One dashboard: its visualizations rendered as native charts, each
/// loading its own analytics query independently so one slow or
/// broken chart never blocks the rest.
class DashboardPage extends StatelessWidget {
  final DashboardEntity dashboard;

  const DashboardPage({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          dashboard.name,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          ConnectivityIndicator(),
          SizedBox(width: AppDimensions.space),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
          children: [
            for (final viz in dashboard.visualizations)
              _ChartCard(vizRef: viz),
            if (dashboard.unsupportedItems > 0)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space),
                child: Text(
                  '${dashboard.unsupportedItems} dashboard '
                  '${dashboard.unsupportedItems == 1 ? 'item' : 'items'} '
                  '(maps, text...) cannot be shown in the app yet.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatefulWidget {
  final DashboardVisualizationRef vizRef;

  const _ChartCard({required this.vizRef});

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  late Future<AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = VisualizationRepositoryImpl().getVisualizationData(
      widget.vizRef,
    );
  }

  void _retry() {
    setState(() {
      _future = VisualizationRepositoryImpl().getVisualizationData(
        widget.vizRef,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vizRef.name,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            FutureBuilder<AnalyticsData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  // A misconfigured chart can never load — say why
                  // and skip the Retry button (it would 409 forever).
                  final error = snapshot.error;
                  final misconfigured =
                      error is MisconfiguredVisualizationException;
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            misconfigured
                                ? error.message
                                : 'Could not load this chart.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (!misconfigured)
                            TextButton(
                              onPressed: _retry,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return Dhis2Chart(data: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

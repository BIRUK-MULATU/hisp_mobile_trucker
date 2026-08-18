import 'package:flutter/material.dart';

import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../data/repositories/local_visualization_repository_impl.dart';
import '../../domain/entities/chart_config.dart';
import '../../domain/usecases/delete_visualization_usecase.dart';
import '../../domain/usecases/get_saved_visualizations_usecase.dart';
import '../pages/chart_edit_page.dart';
import '../pages/chart_view_page.dart';
import '../widgets/chart_type_selector.dart';

/// The Local Dashboard tab: every chart the user has built and saved
/// on THIS device (see [LocalVisualizationRepositoryImpl]) — kept
/// entirely separate from the Server Dashboard tab. Tapping opens the
/// chart; the pencil edits it in place; the bin deletes it after
/// confirmation. The list itself is local-only and instant — only
/// opening a chart needs the server (and even that falls back to a
/// cached result offline).
class ChartsListView extends StatefulWidget {
  final String? searchQuery;

  /// Jump to the Create New tab (used by the empty state's button).
  final VoidCallback onCreateNew;

  const ChartsListView(
      {super.key, this.searchQuery, required this.onCreateNew});

  @override
  State<ChartsListView> createState() => ChartsListViewState();
}

class ChartsListViewState extends State<ChartsListView> {
  final _repository = LocalVisualizationRepositoryImpl();
  late final _getSavedVisualizations = GetSavedVisualizationsUseCase(_repository);
  late final _deleteVisualization = DeleteVisualizationUseCase(_repository);

  List<ChartConfig>? _charts;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final charts = await _getSavedVisualizations();
    if (mounted) setState(() => _charts = charts);
  }

  Future<void> _open(ChartConfig chart) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChartViewPage(config: chart)),
    );
    if (changed == true) await reload();
  }

  Future<void> _edit(ChartConfig chart) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChartEditPage(config: chart)),
    );
    if (changed == true) await reload();
  }

  Future<void> _confirmDelete(ChartConfig chart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete chart?'),
        content: Text('"${chart.name}" will be removed from your charts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteVisualization(chart.id);
    await reload();
  }

  List<ChartConfig> get _filtered {
    final q = widget.searchQuery?.trim().toLowerCase() ?? '';
    final all = _charts ?? const <ChartConfig>[];
    if (q.isEmpty) return all;
    return [
      for (final c in all)
        if (c.name.toLowerCase().contains(q)) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_charts == null) {
      return const AppLoader(message: 'Loading charts...');
    }
    final charts = _filtered;
    if (charts.isEmpty) {
      final query = widget.searchQuery?.trim() ?? '';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                query.isEmpty
                    ? Icons.insert_chart_outlined_rounded
                    : Icons.search_off_rounded,
                size: AppDimensions.iconHuge,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Text(query.isEmpty ? 'No local charts yet' : 'No results',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                query.isEmpty
                    ? 'Build your first chart from your indicators, '
                        'data elements or datasets.'
                    : 'No charts match "$query".',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (query.isEmpty) ...[
                const SizedBox(height: AppDimensions.spaceXL),
                ElevatedButton.icon(
                  onPressed: widget.onCreateNew,
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text('Create New'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: reload,
      // A width-capped grid: one column on phones, more on tablets/
      // desktop, so saved charts use the extra screen space instead
      // of stretching into one very wide column.
      child: ResponsiveContent(
        maxWidth: 1000,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space,
            vertical: AppDimensions.spaceMD,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 460,
            mainAxisExtent: 104,
            crossAxisSpacing: AppDimensions.spaceMD,
            mainAxisSpacing: AppDimensions.spaceSM,
          ),
          itemCount: charts.length,
          itemBuilder: (context, index) {
            final chart = charts[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: InkWell(
                onTap: () => _open(chart),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space,
                    vertical: AppDimensions.spaceSM,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          chartTypeIcon(chart.chartType),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chart.name,
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimensions.spaceXS),
                            Text(
                              chart.summary,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.textSecondary),
                        tooltip: 'Edit chart',
                        onPressed: () => _edit(chart),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.textSecondary),
                        tooltip: 'Delete chart',
                        onPressed: () => _confirmDelete(chart),
                      ),
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

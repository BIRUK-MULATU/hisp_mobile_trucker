import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import 'chart_builder_view.dart';
import 'charts_list_view.dart';

/// The Visualization side of the home toggle: the user's own charts.
/// Two tabs — Charts (the saved list, default) and Create New (the
/// chart builder). Charts are built from the DHIS2 analytics API and
/// stored on the device.
class VisualizationView extends StatefulWidget {
  /// Null while search is closed; otherwise the chart list is
  /// filtered to names containing the query (case-insensitive).
  final String? searchQuery;

  const VisualizationView({super.key, this.searchQuery});

  @override
  State<VisualizationView> createState() => _VisualizationViewState();
}

class _VisualizationViewState extends State<VisualizationView> {
  final _chartsKey = GlobalKey<ChartsListViewState>();
  int _tab = 0;

  void _showCharts() {
    setState(() => _tab = 0);
    _chartsKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedToggle(
          items: const [
            SegmentedToggleItem(
              label: 'Charts',
              icon: Icons.insert_chart_outlined_rounded,
            ),
            SegmentedToggleItem(
              label: 'Create New',
              icon: Icons.add_chart_rounded,
            ),
          ],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          // IndexedStack keeps the builder's half-filled form alive
          // while the user peeks at the Charts tab.
          child: IndexedStack(
            index: _tab,
            children: [
              ChartsListView(
                key: _chartsKey,
                searchQuery: widget.searchQuery,
                onCreateNew: () => setState(() => _tab = 1),
              ),
              ChartBuilderView(onSaved: _showCharts),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/onboarding/tour_helper.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import 'chart_builder_view.dart';
import 'charts_list_view.dart';
import 'dashboards_list_view.dart';

/// The Visualization side of the home toggle. Three tabs — Server
/// Dashboard (default: browses the DHIS2 server's dashboards,
/// mirroring the WebApp's Dashboard app), Local Dashboard (charts
/// built on this device via Create New, see [ChartsListView]), and
/// Create New (the chart builder). Server and Local are two entirely
/// separate lists/storage locations, never merged.
class VisualizationView extends StatefulWidget {
  /// Null while search is closed; otherwise the active tab's list is
  /// filtered to names containing the query (case-insensitive).
  final String? searchQuery;

  const VisualizationView({super.key, this.searchQuery});

  @override
  State<VisualizationView> createState() => _VisualizationViewState();
}

class _VisualizationViewState extends State<VisualizationView> {
  final _chartsKey = GlobalKey<ChartsListViewState>();
  final _toggleShowcaseKey = GlobalKey();
  int _tab = 0;

  void _showLocalDashboard() {
    setState(() => _tab = 1);
    _chartsKey.currentState?.reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeStartTour(
        context,
        tourId: 'visualization',
        keys: [_toggleShowcaseKey],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Showcase(
          key: _toggleShowcaseKey,
          title: 'Dashboards & builder',
          description: 'Switch between server dashboards, your local '
              'charts, and building a new one from indicators, data '
              'elements or datasets.',
          child: SegmentedToggle(
            items: const [
              SegmentedToggleItem(
                label: 'Server Dashboard',
                icon: Icons.space_dashboard_outlined,
              ),
              SegmentedToggleItem(
                label: 'Local Dashboard',
                icon: Icons.phone_android_rounded,
              ),
              SegmentedToggleItem(
                label: 'Create New',
                icon: Icons.add_chart_rounded,
              ),
            ],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          // IndexedStack keeps the builder's half-filled form alive
          // while the user peeks at either dashboard tab.
          child: IndexedStack(
            index: _tab,
            children: [
              DashboardsListView(searchQuery: widget.searchQuery),
              ChartsListView(
                key: _chartsKey,
                searchQuery: widget.searchQuery,
                onCreateNew: () => setState(() => _tab = 2),
              ),
              ChartBuilderView(onSaved: _showLocalDashboard),
            ],
          ),
        ),
      ],
    );
  }
}

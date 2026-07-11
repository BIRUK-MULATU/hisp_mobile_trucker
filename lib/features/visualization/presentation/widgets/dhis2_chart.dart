import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/analytics_data.dart';

/// Renders one DHIS2 visualization natively. The DHIS2 type decides
/// the chart: COLUMN/BAR families → bars, LINE/AREA → lines,
/// PIE → pie, SINGLE_VALUE/GAUGE → the number, everything else
/// (PIVOT_TABLE, unknown types) → a plain data table.
class Dhis2Chart extends StatelessWidget {
  final AnalyticsData data;

  const Dhis2Chart({super.key, required this.data});

  /// Series colors, cycled. First is the app primary so single-series
  /// charts look native to the app.
  static const palette = <Color>[
    AppColors.primary,
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
    Color(0xFF00838F),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  static Color colorOf(int series) => palette[series % palette.length];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No data',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    switch (data.type.toUpperCase()) {
      case 'SINGLE_VALUE':
      case 'GAUGE':
        return _SingleValue(data: data);
      case 'PIE':
        return _Pie(data: data);
      case 'LINE':
      case 'AREA':
      case 'STACKED_AREA':
        return _Lines(data: data, filled: data.type.toUpperCase() != 'LINE');
      case 'COLUMN':
      case 'STACKED_COLUMN':
      case 'BAR':
      case 'STACKED_BAR':
        return _Bars(data: data);
      default:
        return _Table(data: data);
    }
  }
}

// ── Shared bits ────────────────────────────────────────────────

String _compact(double v) {
  if (v.abs() >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Category labels under the x-axis, thinned so they never collide.
/// The text is boxed to a fixed width — DHIS2 names (org units,
/// indicators) are long and would otherwise overflow the row.
Widget _bottomTitle(AnalyticsData data, double value, TitleMeta meta) {
  final i = value.toInt();
  if (i < 0 || i >= data.categories.length) return const SizedBox.shrink();
  final every = (data.categories.length / 6).ceil();
  if (every > 1 && i % every != 0) return const SizedBox.shrink();
  return SideTitleWidget(
    meta: meta,
    space: 4,
    child: SizedBox(
      width: 56,
      child: Text(
        data.categories[i],
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 9,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

/// One legend dot+label, width-capped so any DHIS2 name fits the
/// phone screen (the label ellipsizes instead of overflowing).
class _LegendEntry extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final AnalyticsData data;
  const _Legend({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.series.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceSM),
      child: Wrap(
        spacing: AppDimensions.spaceMD,
        runSpacing: AppDimensions.spaceXS,
        children: [
          for (var i = 0; i < data.series.length; i++)
            _LegendEntry(
              color: Dhis2Chart.colorOf(i),
              label: data.series[i].name,
            ),
        ],
      ),
    );
  }
}

// ── Single value ───────────────────────────────────────────────

class _SingleValue extends StatelessWidget {
  final AnalyticsData data;
  const _SingleValue({required this.data});

  @override
  Widget build(BuildContext context) {
    final v = data.singleValue;
    return SizedBox(
      height: 120,
      child: Center(
        // FittedBox: a wide number shrinks instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            v == null ? '—' : _compact(v),
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 44,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bars ───────────────────────────────────────────────────────

/// Gives a chart at least [minCategoryWidth] px per category: on a
/// phone a 12-month chart scrolls sideways instead of crushing the
/// bars and labels into the screen width.
class _HScrollChart extends StatelessWidget {
  final int categoryCount;
  final Widget child;
  static const minCategoryWidth = 56.0;

  const _HScrollChart({required this.categoryCount, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needed = categoryCount * minCategoryWidth + 48;
        if (needed <= constraints.maxWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: needed, child: child),
        );
      },
    );
  }
}

class _Bars extends StatelessWidget {
  final AnalyticsData data;
  const _Bars({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: _HScrollChart(
            categoryCount: data.categories.length,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => Text(
                        _compact(v),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, meta) => _bottomTitle(data, v, meta),
                    ),
                  ),
                ),
                barGroups: [
                  for (var c = 0; c < data.categories.length; c++)
                    BarChartGroupData(
                      x: c,
                      barRods: [
                        for (var s = 0; s < data.series.length; s++)
                          BarChartRodData(
                            toY: data.series[s].values[c] ?? 0,
                            color: Dhis2Chart.colorOf(s),
                            // ≥56px per category (scrolling guarantees
                            // it), shared between the series' rods.
                            width: (40 / data.series.length).clamp(3.0, 16.0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        _Legend(data: data),
      ],
    );
  }
}

// ── Lines ──────────────────────────────────────────────────────

class _Lines extends StatelessWidget {
  final AnalyticsData data;
  final bool filled;
  const _Lines({required this.data, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: _HScrollChart(
            categoryCount: data.categories.length,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => Text(
                        _compact(v),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, meta) => _bottomTitle(data, v, meta),
                    ),
                  ),
                ),
                lineBarsData: [
                  for (var s = 0; s < data.series.length; s++)
                    LineChartBarData(
                      color: Dhis2Chart.colorOf(s),
                      barWidth: 2.5,
                      isCurved: false,
                      dotData: FlDotData(show: data.categories.length <= 12),
                      belowBarData: BarAreaData(
                        show: filled,
                        color: Dhis2Chart.colorOf(s).withValues(alpha: 0.15),
                      ),
                      spots: [
                        for (var c = 0; c < data.categories.length; c++)
                          if (data.series[s].values[c] != null)
                            FlSpot(c.toDouble(), data.series[s].values[c]!),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        _Legend(data: data),
      ],
    );
  }
}

// ── Pie ────────────────────────────────────────────────────────

class _Pie extends StatelessWidget {
  final AnalyticsData data;
  const _Pie({required this.data});

  @override
  Widget build(BuildContext context) {
    // A pie has one dimension of slices: prefer the categories of the
    // first series; a single-category multi-series viz slices by
    // series instead.
    final bySeries = data.categories.length <= 1 && data.series.length > 1;
    final labels =
        bySeries ? [for (final s in data.series) s.name] : data.categories;
    final values = bySeries
        ? [for (final s in data.series) s.values.first ?? 0]
        : [for (final v in data.series.first.values) v ?? 0];
    final total = values.fold<double>(0, (a, b) => a + b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < values.length; i++)
                  PieChartSectionData(
                    value: values[i],
                    color: Dhis2Chart.colorOf(i),
                    radius: 56,
                    title: total == 0
                        ? ''
                        : '${(values[i] / total * 100).round()}%',
                    titleStyle: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spaceSM),
          child: Wrap(
            spacing: AppDimensions.spaceMD,
            runSpacing: AppDimensions.spaceXS,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < labels.length; i++)
                _LegendEntry(color: Dhis2Chart.colorOf(i), label: labels[i]),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Table fallback (PIVOT_TABLE and unknown types) ─────────────

class _Table extends StatelessWidget {
  final AnalyticsData data;
  const _Table({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 40,
        columnSpacing: AppDimensions.spaceLG,
        headingTextStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        columns: [
          const DataColumn(label: Text('')),
          for (final s in data.series) DataColumn(label: Text(s.name)),
        ],
        rows: [
          for (var c = 0; c < data.categories.length; c++)
            DataRow(cells: [
              DataCell(Text(
                data.categories[c],
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              )),
              for (final s in data.series)
                DataCell(Text(
                  s.values[c] == null ? '' : _compact(s.values[c]!),
                  style: AppTextStyles.bodySmall,
                )),
            ]),
        ],
      ),
    );
  }
}

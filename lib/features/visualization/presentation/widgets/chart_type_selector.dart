import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/chart_config.dart';

IconData chartTypeIcon(ChartType type) => switch (type) {
      ChartType.column => Icons.bar_chart_rounded,
      ChartType.bar => Icons.notes_rounded,
      ChartType.line => Icons.show_chart_rounded,
      ChartType.pie => Icons.pie_chart_rounded,
      ChartType.singleValue => Icons.looks_one_rounded,
      ChartType.gauge => Icons.speed_rounded,
    };

/// Horizontal chip row for picking the chart type.
class ChartTypeSelector extends StatelessWidget {
  final ChartType selected;
  final ValueChanged<ChartType> onChanged;

  const ChartTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final type in ChartType.values)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceSM),
              child: ChoiceChip(
                avatar: Icon(
                  chartTypeIcon(type),
                  size: AppDimensions.iconSM,
                  color: type == selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
                label: Text(type.label),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color:
                      type == selected ? Colors.white : AppColors.textPrimary,
                ),
                selected: type == selected,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.backgroundGrey,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(
                    color: type == selected
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                onSelected: (_) => onChanged(type),
              ),
            ),
        ],
      ),
    );
  }
}

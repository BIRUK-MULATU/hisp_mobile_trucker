import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/outlier_stats.dart';

/// One-line comparison shown under a numeric cell while the user
/// types: the cell's actual previous values ("Last 3: 12 · 14 · 13")
/// and whether the value being entered is higher or lower than them.
///
/// Informative only, same spirit as the outlier check it shares its
/// history with — the user can ignore it and type anything, the value
/// is never blocked. Renders nothing when there is no previous history
/// for the cell, or when what's in the cell right now isn't numeric.
class PreviousEntriesHint extends StatelessWidget {
  const PreviousEntriesHint({
    super.key,
    required this.value,
    required this.recent,
    this.count = 3,
  });

  /// The raw text currently in the cell.
  final String value;

  /// The cell's newest historical values, newest-first.
  final List<HistoryEntry> recent;

  /// How many previous entries to show.
  final int count;

  static String _num(double v) {
    if (!v.isFinite) return '—';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  }

  /// ("higher"|"lower"|null, widget) for the badge next to the list.
  (String?, Color) get _relation {
    final current = double.tryParse(value.trim());
    if (current == null || recent.isEmpty) return (null, AppColors.textSecondary);
    final shown = recent.take(count).map((e) => e.value);
    final max = shown.reduce((a, b) => a > b ? a : b);
    final min = shown.reduce((a, b) => a < b ? a : b);
    if (current > max) return ('▲ Higher than last $count', AppColors.warning);
    if (current < min) return ('▼ Lower than last $count', AppColors.warning);
    return ('≈ Within last $count', AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    final current = double.tryParse(value.trim());
    if (current == null || recent.isEmpty) return const SizedBox.shrink();

    final shown = recent.take(count).toList();
    final (relation, color) = _relation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceSM + AppDimensions.spaceXS,
        AppDimensions.spaceXXS,
        AppDimensions.spaceSM,
        AppDimensions.spaceXS,
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.spaceXXS),
          Expanded(
            child: Text(
              'Last $count: ${shown.map((e) => _num(e.value)).join(' · ')}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          if (relation != null)
            Text(
              relation,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
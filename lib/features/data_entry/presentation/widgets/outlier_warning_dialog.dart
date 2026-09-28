import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/outlier_stats.dart';

/// One flagged value waiting for the user's confirmation, as collected
/// by the save-time check: which cell it belongs to, and the verdict.
class OutlierWarning {
  const OutlierWarning({required this.label, required this.verdict});

  /// "Malaria cases · Under 5 years" — the cell's identity in the form.
  final String label;
  final OutlierVerdict verdict;
}

/// Popup shown when Save is tapped on a form holding values the outlier
/// check flags as far outside what this cell normally reports.
///
/// Warn, never block: "Save anyway" always lets the values through,
/// matching the contract validation rules already follow. Returns true
/// when the user chose to save, false (or null, treated as false) when
/// they want to go back and correct the value.
Future<bool> showOutlierWarning(
  BuildContext context, {
  required List<OutlierWarning> warnings,
}) async {
  final kept = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _OutlierWarningDialog(warnings: warnings),
  );
  return kept ?? false;
}

class _OutlierWarningDialog extends StatelessWidget {
  const _OutlierWarningDialog({required this.warnings});

  final List<OutlierWarning> warnings;

  static String _num(double v) {
    if (!v.isFinite) return '—';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  }

  /// "34, 38, and 40" — Oxford-comma list, so a sentence with numbers
  /// in it reads the way a person would say it.
  static String _list(Iterable<String> parts) {
    final p = parts.toList();
    if (p.length <= 1) return p.join('');
    if (p.length == 2) return '${p[0]} and ${p[1]}';
    return '${p.sublist(0, p.length - 1).join(', ')}, and ${p.last}';
  }

  /// "higher" / "lower" / "outside" — where the typed value sits
  /// against the previous values the dialog quotes.
  static String _direction(OutlierVerdict v) {
    final prev = v.previousValues;
    if (prev.isEmpty) return 'outside';
    if (v.value > prev.reduce(math.max)) return 'significantly higher than';
    if (v.value < prev.reduce(math.min)) return 'significantly lower than';
    return 'outside the usual range of';
  }

  /// "month" / "months" for the number of previous periods quoted.
  static String _periods(int n) => n == 1 ? 'month' : 'months';

  /// The headline sentence for one value — the whole reason the dialog
  /// is on screen, so it states the comparison in full rather than
  /// deferring to numbers in a table.
  Widget _oneSentence(OutlierWarning w) {
    final v = w.verdict;
    final previous = _list(v.previousValues.map(_num));
    final span = 'the previous ${v.recent.length} '
        '${_periods(v.recent.length)}';
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodyMedium,
        children: [
          const TextSpan(text: 'The values for '),
          TextSpan(text: '$span were '),
          TextSpan(
            text: previous,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ', but you entered '),
          TextSpan(
            text: _num(v.value),
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ' for this month. This value appears to be '),
          TextSpan(
            text: _direction(v),
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' $span.'),
        ],
      ),
    );
  }

  /// One row of the multi-value form: which cell, its previous values,
  /// and what was typed instead.
  Widget _oneRow(OutlierWarning w) {
    final v = w.verdict;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            w.label,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text.rich(
            TextSpan(
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary),
              children: [
                TextSpan(text: 'Last ${v.recent.length}: '),
                TextSpan(
                  text: v.previousValues.map(_num).join(' · '),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '   →   you entered '),
                TextSpan(
                  text: _num(v.value),
                  style: AppTextStyles.labelMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' (${_direction(v)})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final single = warnings.length == 1;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spaceLG),
      ),
      title: const Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.warningLight,
            child: Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: AppDimensions.iconLG),
          ),
          SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: Text('Are you sure?', style: AppTextStyles.headingSmall),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (single)
              _oneSentence(warnings.first)
            else ...[
              Text(
                '${warnings.length} values look very different from what '
                'these cells normally report. Check each one before saving.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              for (final w in warnings) _oneRow(w),
            ],
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              single
                  ? 'If the figure is genuinely this high or low, save it '
                      'as it is.'
                  : 'Save them as they are if they are correct.',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(single ? 'Go back and correct' : 'Go back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          child: Text(single ? 'Save value' : 'Save anyway'),
        ),
      ],
    );
  }
}

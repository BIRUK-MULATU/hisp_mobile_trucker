import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/outlier_stats.dart';

/// Popup shown right after the user types a value that fails the live
/// outlier check. Informative only — "Keep value" always lets them
/// through, matching the warn-never-block contract of validation rules.
///
/// Returns true when the user chose to keep the value as typed, false
/// (or null, treated as false) when they want to go back and fix it.
Future<bool> showOutlierWarning(
  BuildContext context, {
  required OutlierVerdict verdict,
  required String elementName,
  required String cocName,
}) async {
  final kept = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _OutlierWarningDialog(
      verdict: verdict,
      elementName: elementName,
      cocName: cocName,
    ),
  );
  return kept ?? false;
}

class _OutlierWarningDialog extends StatelessWidget {
  const _OutlierWarningDialog({
    required this.verdict,
    required this.elementName,
    required this.cocName,
  });

  final OutlierVerdict verdict;
  final String elementName;
  final String cocName;

  static String _num(double v) {
    if (!v.isFinite) return '—';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final field = cocName.isEmpty || cocName == 'default'
        ? elementName
        : '$elementName · $cocName';
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
            child: Text('Possible outlier', style: AppTextStyles.headingSmall),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyMedium,
              children: [
                const TextSpan(text: 'You entered '),
                TextSpan(
                  text: _num(verdict.value),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' for $field.'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Recent range',
                    '${_num(verdict.historicalMin)} – ${_num(verdict.historicalMax)}'),
                _row('Typical', '≈ ${_num(verdict.typical)}'),
                _row('Expected',
                    '${_num(verdict.lowerBound)} – ${_num(verdict.upperBound)}'),
                _row('Based on', '${verdict.n} recent periods'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            'Double-check the figure. If it is genuinely this high or low, '
            'keep it and carry on.',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Let me fix it'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          child: const Text('Keep value'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/outlier_stats.dart';

/// Bottom sheet for choosing the live outlier-check algorithm and
/// threshold. Returns the new [OutlierConfig] on save, or null if
/// dismissed.
Future<OutlierConfig?> showOutlierSettings(
  BuildContext context, {
  required OutlierConfig current,
}) {
  return showModalBottomSheet<OutlierConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
    ),
    builder: (context) => _OutlierSettingsSheet(current: current),
  );
}

class _OutlierSettingsSheet extends StatefulWidget {
  const _OutlierSettingsSheet({required this.current});

  final OutlierConfig current;

  @override
  State<_OutlierSettingsSheet> createState() => _OutlierSettingsSheetState();
}

class _OutlierSettingsSheetState extends State<_OutlierSettingsSheet> {
  late OutlierAlgorithm _algorithm = widget.current.algorithm;
  late double _threshold = widget.current.threshold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.space,
        right: AppDimensions.space,
        top: AppDimensions.space,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.space,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.space),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const Text('Outlier check', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            'How the form decides a value you type is unusual, compared '
            'with this facility\'s recent history.',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.space),
          RadioGroup<OutlierAlgorithm>(
            groupValue: _algorithm,
            onChanged: (v) => setState(() => _algorithm = v ?? _algorithm),
            child: Column(
              children: [
                for (final a in OutlierAlgorithm.values)
                  RadioListTile<OutlierAlgorithm>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.primary,
                    value: a,
                    title: Text(a.label, style: AppTextStyles.bodyMedium),
                    subtitle: Text(a.shortDescription,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Row(
            children: [
              const Text('Threshold', style: AppTextStyles.labelLarge),
              const SizedBox(width: AppDimensions.spaceSM),
              Text(
                _threshold.toStringAsFixed(1),
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                _threshold <= 2
                    ? 'more sensitive'
                    : _threshold >= 4
                        ? 'less sensitive'
                        : 'balanced',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Slider(
            value: _threshold.clamp(1.0, 5.0),
            min: 1.0,
            max: 5.0,
            divisions: 8,
            activeColor: AppColors.primary,
            label: _threshold.toStringAsFixed(1),
            onChanged: (v) => setState(() => _threshold = v),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightMD,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                OutlierConfig(algorithm: _algorithm, threshold: _threshold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

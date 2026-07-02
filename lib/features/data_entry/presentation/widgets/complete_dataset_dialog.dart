import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class CompleteDataSetDialog extends StatelessWidget {
  final VoidCallback onNotNow;
  final VoidCallback onComplete;
  final bool isCompleting;

  const CompleteDataSetDialog({
    super.key,
    required this.onNotNow,
    required this.onComplete,
    this.isCompleting = false,
  });

  /// Show the bottom sheet
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (_) => CompleteDataSetDialog(
        onNotNow: () => Navigator.pop(context, false),
        onComplete: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.spaceXXL,
        AppDimensions.pagePaddingH,
        AppDimensions.spaceXXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────
          Text(
            'Everything looks good',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMD),

          // ── Message ────────────────────────────────
          Text(
            'Do you also want to complete the data set ?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          const Divider(color: AppColors.divider, height: 1),

          const SizedBox(height: AppDimensions.spaceXL),

          // ── Buttons ────────────────────────────────
          Row(
            children: [
              // ── Not Now ──────────────────────────
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      isCompleting ? null : onNotNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceMD),
                  ),
                  child: Text(
                    'Not now',
                    style: AppTextStyles.buttonMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.spaceMD),

              // ── Complete ──────────────────────────
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isCompleting ? null : onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceMD),
                  ),
                  child: isCompleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Complete',
                          style: AppTextStyles.buttonMedium
                              .copyWith(
                                  color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

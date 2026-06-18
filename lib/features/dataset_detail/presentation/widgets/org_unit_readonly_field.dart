import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class OrgUnitReadOnlyField extends StatelessWidget {
  final String? orgUnitName;
  final bool isLoading;

  const OrgUnitReadOnlyField({
    super.key,
    this.orgUnitName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ─────────────────────────────────────
        Text(
          'Org unit',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceSM),

        // ── Read-only value + bottom border ───────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            bottom: AppDimensions.spaceSM,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        orgUnitName ?? '—',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: orgUnitName != null
                              ? AppColors.textSecondary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    // Lock icon shows field is not editable
                    if (orgUnitName != null)
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: AppDimensions.iconSM,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../pages/org_unit_selector_page.dart';

class OrgUnitField extends StatelessWidget {
  final String? orgUnitName;
  final String? orgUnitId;
  final bool isLoading;
  final ValueChanged<Map<String, String>>? onSelected;

  const OrgUnitField({
    super.key,
    this.orgUnitName,
    this.orgUnitId,
    this.isLoading = false,
    this.onSelected,
  });

  Future<void> _openSelector(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OrgUnitSelectorPage(
          preSelectedId: orgUnitId,
        ),
      ),
    );

    if (result != null && onSelected != null) {
      onSelected!({
        'id': result['id'] as String,
        'name': result['name'] as String,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _openSelector(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ──────────────────────────────────
          Text(
            'Org unit',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: AppDimensions.spaceSM),

          // ── Value row with bottom border ───────────
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
                          orgUnitName ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: orgUnitName != null
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      // Chevron shows it's tappable
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: AppDimensions.iconMD,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

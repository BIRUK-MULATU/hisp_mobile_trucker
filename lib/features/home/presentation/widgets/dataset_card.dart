import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/dataset_entity.dart';
import 'dataset_icon_helper.dart';

class DataSetCard extends StatelessWidget {
  final DataSetEntity dataSet;
  final VoidCallback? onTap;
  final VoidCallback? onSync;

  const DataSetCard({
    super.key,
    required this.dataSet,
    this.onTap,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = DataSetIconHelper.getColor(dataSet.name);
    final icon = DataSetIconHelper.getIcon(dataSet.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space,
          vertical: AppDimensions.spaceXS + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceMD,
          ),
          child: Row(
            children: [
              // ── Icon Container ──────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: AppDimensions.iconXL,
                ),
              ),

              const SizedBox(width: AppDimensions.spaceMD),

              // ── Title + Chips ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      dataSet.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimensions.spaceXS + 2),

                    // Status chips row
                    Row(
                      children: [
                        _StatusChip(
                          label: 'Synced',
                          icon: Icons.check_circle_rounded,
                          isActive:
                              dataSet.syncStatus == SyncStatus.synced,
                          activeColor: AppColors.success,
                        ),
                        const SizedBox(width: AppDimensions.spaceMD),
                        _StatusChip(
                          label: 'unsync',
                          icon: Icons.sync_problem_rounded,
                          isActive:
                              dataSet.syncStatus == SyncStatus.unsynced,
                          activeColor: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Chevron ─────────────────────────────
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: AppDimensions.iconLG,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: AppConstants.animNormal),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM + 4,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.10)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.35)
              : AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: activeColor.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isActive ? activeColor : AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spaceXXS),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color:
                  isActive ? activeColor : AppColors.textSecondary,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

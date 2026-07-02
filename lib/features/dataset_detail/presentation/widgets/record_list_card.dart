import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/utils/ethiopian_calendar.dart';

enum RecordSyncStatus { synced, unsynced }

class RecordListCard extends StatelessWidget {
  final String period;
  final String orgUnitName;
  final String date;
  final bool isCompleted;
  final RecordSyncStatus syncStatus;
  final VoidCallback? onTap;

  const RecordListCard({
    super.key,
    required this.period,
    required this.orgUnitName,
    required this.date,
    this.isCompleted = false,
    this.syncStatus = RecordSyncStatus.unsynced,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space,
          vertical: AppDimensions.spaceXS,
        ),
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left content ───────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Period + Date ───────────────
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${EthiopianCalendar.formatPeriodId(period)}  $date',
                        style:
                            AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: AppDimensions.spaceXS),

                  // ── Org Unit ────────────────────
                  Text(
                    'Registered in : $orgUnitName',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                      height: AppDimensions.spaceXS),

                  // ── Completed status ────────────
                  if (isCompleted)
                    Row(
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: AppDimensions.iconSM,
                        ),
                        const SizedBox(
                            width: AppDimensions.spaceXXS),
                        Text(
                          'Completed',
                          style: AppTextStyles.bodySmall
                              .copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppDimensions.spaceSM),

            // ── Sync chip ──────────────────────────
            _SyncChip(status: syncStatus),
          ],
        ),
      ),
    );
  }
}

// ── Sync Status Chip ───────────────────────────────────────────
class _SyncChip extends StatelessWidget {
  final RecordSyncStatus status;
  const _SyncChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSynced = status == RecordSyncStatus.synced;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM,
        vertical: AppDimensions.spaceXXS + 1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isSynced
              ? AppColors.border
              : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isSynced ? 'Synced' : 'unsync',
        style: AppTextStyles.caption.copyWith(
          color: isSynced
              ? AppColors.textSecondary
              : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

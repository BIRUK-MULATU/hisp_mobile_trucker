import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Shown wherever a live query failed and a local cache stood in
/// instead — the Dashboards list, one dashboard's item list, and each
/// dashboard chart card can all independently fall back to a stale
/// answer, so this is a small reusable strip rather than duplicated
/// per screen.
class OfflineCacheBanner extends StatelessWidget {
  final DateTime? cachedAt;

  const OfflineCacheBanner({super.key, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final when = cachedAt == null
        ? ''
        : ' from ${cachedAt!.toLocal().toString().substring(0, 16)}';
    return Container(
      width: double.infinity,
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: AppDimensions.iconSM, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              'Offline — showing cached data$when',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

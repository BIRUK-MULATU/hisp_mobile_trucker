import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

/// Centered, scroll-fill-friendly empty/message view used by the
/// report list, the "Reports to fill" list and anywhere a quiet
/// `icon + title + message` state beats a blank screen.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
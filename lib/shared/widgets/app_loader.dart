import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const AppLoader({
    super.key,
    this.message,
    this.color,
    this.size = AppDimensions.iconXXL,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: AppLoader(
        message: message,
        color: AppColors.textOnPrimary,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom-right "add" action drawn as a squircle (a softly rounded
/// square) instead of Flutter's stock circular FAB — a crisp vector
/// shape, so it stays sharp at any size instead of the fixed
/// resolution of a bitmap icon.
class SquircleFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  const SquircleFab({
    super.key,
    required this.onPressed,
    this.tooltip = 'New report',
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.32);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primary,
        borderRadius: radius,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.45),
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

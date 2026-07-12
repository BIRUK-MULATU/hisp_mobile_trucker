import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class SegmentedToggleItem {
  final String label;
  final IconData icon;

  const SegmentedToggleItem({required this.label, required this.icon});
}

/// A segmented pill with a single sliding thumb: the blue highlight
/// glides (with a slight overshoot) to the tapped segment while the
/// labels cross-fade, instead of each segment repainting its own
/// background.
class SegmentedToggle extends StatelessWidget {
  final List<SegmentedToggleItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  const SegmentedToggle({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  }) : assert(items.length >= 2);

  static const _duration = Duration(milliseconds: 320);

  void _select(int next) {
    HapticFeedback.selectionClick();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOutBack,
              // -1..1 across the segments: segment 0 is hard left,
              // the last is hard right.
              alignment: Alignment(
                items.length == 1
                    ? 0
                    : -1 + 2 * index / (items.length - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / items.length,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  _SegmentButton(
                    item: items[i],
                    isActive: i == index,
                    onTap: () => _select(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final SegmentedToggleItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        // The content paints no background of its own, so make the
        // whole segment tappable, not just the label.
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // One 0→1 progress drives icon and label colors so they fade
        // in step with the thumb sliding underneath.
        child: TweenAnimationBuilder<double>(
          duration: SegmentedToggle._duration,
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: isActive ? 1 : 0),
          builder: (context, t, _) {
            final color =
                Color.lerp(AppColors.textSecondary, Colors.white, t)!;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.0 : 0.85,
                  duration: SegmentedToggle._duration,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    item.icon,
                    size: AppDimensions.iconMD,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceXS),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: color,
                      fontWeight:
                          FontWeight.lerp(FontWeight.w500, FontWeight.w700, t),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

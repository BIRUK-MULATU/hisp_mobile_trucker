import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// A grid of round-radio pill options — the layout the capture DATE
/// filter uses, shared here so any other single-choice picker (e.g.
/// the chart builder's relative period picker) looks and behaves
/// identically instead of just similarly.
class OptionGrid extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  /// Radio ring border + fill color for the selected dot.
  final Color color;

  /// Label text color — defaults to [color] (right for a colored
  /// sheet like the filter panel); pass a separate color for a plain
  /// background where the ring should stay accented but the text
  /// should read as normal body text.
  final Color? textColor;

  final int crossAxisCount;
  final double childAspectRatio;
  final int maxLines;

  const OptionGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.color,
    this.textColor,
    this.crossAxisCount = 3,
    this.childAspectRatio = 2.4,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spaceXS,
      crossAxisSpacing: AppDimensions.spaceXS,
      childAspectRatio: childAspectRatio,
      children: [
        for (final option in options)
          _RadioPillOption(
            label: option,
            selected: option == selected,
            onTap: () => onSelected(option),
            color: color,
            textColor: textColor ?? color,
            maxLines: maxLines,
          ),
      ],
    );
  }
}

class _RadioPillOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final int maxLines;

  const _RadioPillOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.textColor,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                  color: Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, color: color),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(color: textColor),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

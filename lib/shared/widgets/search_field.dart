import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Small reusable search input: rounded, grey-filled, search icon
/// leading, clear button trailing once there's text to clear.
class SearchField extends StatelessWidget {
  final String hint;
  final String value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;

  /// Extra icon shown after the clear button — e.g. a
  /// collapse/expand chevron for a search that also drives a
  /// dropdown. Null shows just the clear button (or nothing).
  final Widget? trailing;

  const SearchField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textSecondary, size: AppDimensions.iconMD),
        suffixIcon: (value.isEmpty && trailing == null)
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        controller?.clear();
                        onChanged('');
                      },
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
        filled: true,
        fillColor: AppColors.backgroundGrey,
        contentPadding:
            const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

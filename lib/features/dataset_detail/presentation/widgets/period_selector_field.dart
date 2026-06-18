import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class PeriodSelectorField extends StatefulWidget {
  final String? selectedPeriod;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const PeriodSelectorField({
    super.key,
    this.selectedPeriod,
    required this.onChanged,
    this.validator,
  });

  @override
  State<PeriodSelectorField> createState() =>
      _PeriodSelectorFieldState();
}

class _PeriodSelectorFieldState extends State<PeriodSelectorField> {
  late final List<_PeriodOption> _periods;

  @override
  void initState() {
    super.initState();
    _periods = _generatePeriods();
  }

  List<_PeriodOption> _generatePeriods() {
    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return List.generate(24, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      final month = date.month.toString().padLeft(2, '0');
      return _PeriodOption(
        id: '${date.year}$month',
        label: '${monthNames[date.month - 1]} ${date.year}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Period',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        DropdownButtonFormField<String>(
          // Use initialValue pattern — not deprecated value
          key: ValueKey(widget.selectedPeriod),
          initialValue: widget.selectedPeriod,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            filled: false,
            contentPadding:
                EdgeInsets.only(bottom: AppDimensions.spaceSM),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          items: _periods
              .map((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(p.label,
                        style: AppTextStyles.bodyMedium),
                  ))
              .toList(),
          onChanged: widget.onChanged,
          validator: widget.validator,
        ),
      ],
    );
  }
}

class _PeriodOption {
  final String id;
  final String label;
  const _PeriodOption({required this.id, required this.label});
}

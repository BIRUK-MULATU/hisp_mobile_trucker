import 'package:flutter/material.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class PeriodSelectorField extends StatefulWidget {
  final String? selectedPeriod;
  final String periodType;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const PeriodSelectorField({
    super.key,
    this.selectedPeriod,
    this.periodType = 'Monthly',
    required this.onChanged,
    this.validator,
  });

  @override
  State<PeriodSelectorField> createState() => _PeriodSelectorFieldState();
}

class _PeriodSelectorFieldState extends State<PeriodSelectorField> {
  late List<EthiopianPeriod> _periods;

  @override
  void initState() {
    super.initState();
    _periods = EthiopianCalendar.generatePeriods(
      periodType: widget.periodType,
      count: 24,
    );
  }

  @override
  void didUpdateWidget(PeriodSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodType != widget.periodType) {
      setState(() {
        _periods = EthiopianCalendar.generatePeriods(
          periodType: widget.periodType,
          count: 24,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label in English ───────────────────────
        Text(
          'Report Period',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceSM),

        // ── Dropdown with Amharic months ───────────
        DropdownButtonFormField<String>(
          key: ValueKey(widget.selectedPeriod ?? 'none'),
          initialValue: widget.selectedPeriod,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            filled: false,
            contentPadding: EdgeInsets.only(bottom: AppDimensions.spaceSM),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          items: _periods
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    p.label, // Amharic: "መስከረም 2017"
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
              .toList(),
          onChanged: widget.onChanged,
          validator: widget.validator ??
              (value) => value == null ? 'Please select a report period' : null,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class AddRecordPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;

  const AddRecordPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgUnitController = TextEditingController();
  final _periodController = TextEditingController();
  bool _isLoading = false;

  // Period options for dropdown
  final List<String> _periods = _generatePeriods();

  static List<String> _generatePeriods() {
    final now = DateTime.now();
    final periods = <String>[];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final month = date.month.toString().padLeft(2, '0');
      periods.add('${date.year}$month');
    }
    return periods;
  }

  String? _selectedPeriod;

  @override
  void dispose() {
    _orgUnitController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Record',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spaceLG),

              // ── Dataset Name (read only) ───────────────
              _SectionLabel(label: 'Dataset'),
              const SizedBox(height: AppDimensions.spaceSM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  widget.dataSetName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // ── Period Selector ───────────────────────
              _SectionLabel(label: 'Period *'),
              const SizedBox(height: AppDimensions.spaceSM),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space,
                    vertical: AppDimensions.spaceMD,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 2),
                  ),
                  hintText: 'Select period',
                  hintStyle: AppTextStyles.inputHint,
                ),
                items: _periods
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          _formatPeriod(p),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedPeriod = value),
                validator: (value) =>
                    value == null ? 'Please select a period' : null,
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // ── Organisation Unit ─────────────────────
              _SectionLabel(label: 'Organisation Unit *'),
              const SizedBox(height: AppDimensions.spaceSM),
              AppTextField(
                hintText: 'Enter organisation unit',
                controller: _orgUnitController,
                suffixIcon: const Padding(
                  padding:
                      EdgeInsets.only(right: AppDimensions.spaceMD),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: AppDimensions.iconLG,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter organisation unit';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.spaceXXXL),

              // ── Submit Button ─────────────────────────
              AppButton(
                label: 'Create Record',
                isLoading: _isLoading,
                onPressed: _submit,
                variant: AppButtonVariant.secondary,
                prefixIcon: _isLoading
                    ? null
                    : const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: AppDimensions.iconMD,
                      ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPeriod(String period) {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = int.tryParse(period.substring(4, 6)) ?? 1;
      const months = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ];
      return '${months[month - 1]} $year';
    }
    return period;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/period_selector_field.dart';
import 'org_unit_selector_page.dart';

class AddRecordPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;

  const AddRecordPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    this.periodType = 'Monthly',
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = SecureStorage();

  String? _orgUnitName;
  String? _orgUnitId;
  String? _selectedPeriodId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrgUnit();
  }

  Future<void> _loadOrgUnit() async {
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    if (mounted && orgUnit != null) {
      setState(() {
        _orgUnitId = orgUnit['id'] as String?;
        _orgUnitName = orgUnit['displayName'] as String?
            ?? orgUnit['name'] as String?
            ?? orgUnit['shortName'] as String?;
      });
    }
  }

  Future<void> _openOrgUnitSelector() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OrgUnitSelectorPage(
          preSelectedId: _orgUnitId,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _orgUnitId = result['id'] as String?;
        _orgUnitName = result['name'] as String?;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_orgUnitId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No organisation unit found. Contact your administrator.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isSubmitting = false);
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
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.dataSetName,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

              // ── Top Icon ────────────────────────────
              _TopIconSection(
                  onClose: () => Navigator.pop(context)),

              const SizedBox(height: AppDimensions.spaceXXL),

              // ── Org Unit (Read Only) ─────────────────
              _OrgUnitField(
                orgUnitName: _orgUnitName,
                onTap: _openOrgUnitSelector,
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              // ── Report Period (Amharic months only) ──
              PeriodSelectorField(
                selectedPeriod: _selectedPeriodId,
                periodType: widget.periodType,
                onChanged: (value) =>
                    setState(() => _selectedPeriodId = value),
              ),

              const SizedBox(height: AppDimensions.spaceGiant),

              // ── Submit Button (English) ──────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLG,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create Record',
                          style: AppTextStyles.buttonLarge
                              .copyWith(color: Colors.white),
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

// ── Top Icon ───────────────────────────────────────────────────
class _TopIconSection extends StatelessWidget {
  final VoidCallback onClose;
  const _TopIconSection({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(Icons.grid_view_rounded,
              color: AppColors.primary,
              size: AppDimensions.iconXL),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Org Unit Field ─────────────────────────────────────────────
class _OrgUnitField extends StatelessWidget {
  final String? orgUnitName;
  final VoidCallback? onTap;
  const _OrgUnitField({this.orgUnitName, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Org unit',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                bottom: AppDimensions.spaceSM),
            decoration: const BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    orgUnitName ?? 'Loading...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: orgUnitName != null
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: AppDimensions.iconMD,
                    color: AppColors.textHint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

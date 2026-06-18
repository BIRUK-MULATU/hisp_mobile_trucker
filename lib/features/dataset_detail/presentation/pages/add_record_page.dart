import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/org_unit_readonly_field.dart';
import '../widgets/period_selector_field.dart';

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
  final _secureStorage = SecureStorage();

  String? _orgUnitName;
  String? _orgUnitId;
  String? _selectedPeriod;
  bool _isLoadingOrgUnit = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrgUnit();
  }

  // ── Load org unit from storage (saved at login) ────────────
  Future<void> _loadOrgUnit() async {
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    if (mounted) {
      setState(() {
        _orgUnitId = orgUnit?['id'] as String?;
        _orgUnitName = orgUnit?['displayName'] as String? ??
            orgUnit?['name'] as String?;
        _isLoadingOrgUnit = false;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_orgUnitId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No organisation unit assigned to your account. Contact your administrator.'),
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
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Icon Section ─────────────────────
            _TopIconSection(dataSetName: widget.dataSetName),

            // ── Form Fields ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.spaceXL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Org Unit (Read Only) ──────────
                    OrgUnitReadOnlyField(
                      orgUnitName: _orgUnitName,
                      isLoading: _isLoadingOrgUnit,
                    ),

                    const SizedBox(height: AppDimensions.spaceXXL),

                    // ── Report Period ─────────────────
                    PeriodSelectorField(
                      selectedPeriod: _selectedPeriod,
                      onChanged: (value) =>
                          setState(() => _selectedPeriod = value),
                      validator: (value) => value == null
                          ? 'Please select a report period'
                          : null,
                    ),

                    const SizedBox(height: AppDimensions.spaceXXXL),
                    const SizedBox(height: AppDimensions.spaceXXXL),

                    // ── Submit Button ─────────────────
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
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.dataSetName,
        style: AppTextStyles.appBarTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Top Icon Section ───────────────────────────────────────────
class _TopIconSection extends StatelessWidget {
  final String dataSetName;

  const _TopIconSection({required this.dataSetName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main icon circle ─────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: AppDimensions.iconXL,
            ),
          ),

          // ── X button on top right of circle ──────
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

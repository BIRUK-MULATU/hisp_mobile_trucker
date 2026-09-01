import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../views/capture_org_unit_view.dart';

/// Entry point for the Report Period list's FAB: the same
/// org unit → dataset → period → section → data entry workflow that
/// used to be Capture mode's whole body, now reached only when the
/// user explicitly starts a new report.
class NewReportPage extends StatelessWidget {
  const NewReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Read ABOVE the Scaffold — inside the body, Scaffold removes
    // viewInsets.bottom once it has resized, so MediaQuery there
    // always reports 0 (see CaptureOrgUnitView.keyboardOpen docs).
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Report', style: AppTextStyles.appBarTitle),
      ),
      body: CaptureOrgUnitView(keyboardOpen: keyboardOpen),
    );
  }
}

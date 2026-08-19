import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/chart_config.dart';
import '../views/chart_builder_view.dart';

/// Full-screen wrapper around [ChartBuilderView] for editing an
/// existing local chart — the builder itself has no AppBar since it's
/// normally embedded as a tab; this gives it one plus a back button
/// when pushed standalone. Pops `true` on a successful save so the
/// caller (which is showing a now-stale copy of the chart) knows to
/// refresh.
class ChartEditPage extends StatelessWidget {
  final ChartConfig config;

  const ChartEditPage({super.key, required this.config});

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
        title: const Text('Edit Chart', style: AppTextStyles.appBarTitle),
      ),
      body: ChartBuilderView(
        editing: config,
        onSaved: () => Navigator.pop(context, true),
      ),
    );
  }
}

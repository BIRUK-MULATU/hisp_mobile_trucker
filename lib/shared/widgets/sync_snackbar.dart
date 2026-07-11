import 'package:flutter/material.dart';
import '../../core/sync/manual_sync.dart';
import '../theme/app_colors.dart';

/// One look for every manual-sync outcome, wherever the button lives.
void showSyncResultSnackBar(BuildContext context, ManualSyncResult result) {
  final color = switch (result.outcome) {
    ManualSyncOutcome.offline || ManualSyncOutcome.failed => AppColors.error,
    ManualSyncOutcome.partial => AppColors.warning,
    ManualSyncOutcome.nothingToSync ||
    ManualSyncOutcome.uploaded =>
      AppColors.success,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(result.message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
}

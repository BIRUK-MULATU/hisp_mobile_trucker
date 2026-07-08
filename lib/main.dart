import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/sync/sync_coordinator.dart';
import 'core/sync/drift_sync_manager.dart';
import 'shared/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // A server URL saved in Settings overrides the compiled default.
  final storedBaseUrl = await SecureStorage().getBaseUrl();
  if (storedBaseUrl != null && storedBaseUrl.isNotEmpty) {
    ApiClient().updateBaseUrl(storedBaseUrl);
  }

  // Auto-sync: pushes queued offline writes (pending data values and
  // completions) whenever connectivity returns. No-ops while logged out.
  SyncCoordinator(
    networkInfo: ConnectivityNetworkInfo(),
    syncManager: DriftSyncManager.instance,
  ).start();

  runApp(const HispMobileTrackerApp());
}

class HispMobileTrackerApp extends StatelessWidget {
  const HispMobileTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ── App Config ──────────────────────────────────
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────
      theme: AppTheme.lightTheme,

      // ── Router ──────────────────────────────────────
      routerConfig: AppRouter.router,
    );
  }
}

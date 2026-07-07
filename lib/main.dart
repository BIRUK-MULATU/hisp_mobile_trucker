import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'debug/test_login_page.dart';

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

  runApp(const HispMobileTrackerApp());
}

class HispMobileTrackerApp extends StatelessWidget {
  const HispMobileTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── App Config ──────────────────────────────────
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────
      theme: AppTheme.lightTheme,

      // ── DEBUG: test login -> debug screen on success ──
      home: const TestLoginPage(),
      // Restore for the real app:
      // routerConfig: AppRouter.router,  (use MaterialApp.router)
    );
  }
}

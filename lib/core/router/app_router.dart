import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/app_session.dart';
import '../onboarding/onboarding_service.dart';
import '../../debug/debug_sync_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  AppRouter._();

  // ── Route Paths ────────────────────────────────────────────
  // Detail flows (dataset detail, data entry) are pushed with
  // MaterialPageRoute and are intentionally not listed here.
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';

  // ── Router ─────────────────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: login,
    debugLogDiagnostics: kDebugMode,
    // Auth guard: every screen except login requires an active session.
    // AppSession notifies on login/logout so this re-evaluates.
    refreshListenable: AppSession.instance,
    redirect: (context, state) {
      // Onboarding is always reachable directly (first run AND a
      // deliberate replay from Settings/the drawer) — never bounced
      // away from by the rules below.
      if (state.matchedLocation == onboarding) return null;
      if (!OnboardingService.hasSeenOnboarding) return onboarding;

      final loggedIn = AppSession.instance.isLoggedIn;
      final goingToLogin = state.matchedLocation == login;
      if (!loggedIn && !goingToLogin) return login;
      if (loggedIn && goingToLogin) return home;
      return null;
    },
    routes: [
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => LoginPage(
          sessionExpired:
              state.uri.queryParameters['reason'] == 'session-expired',
        ),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      // TEMPORARY dev-only route: browse the local DB tables in-app.
      // Remove before shipping — not linked from any UI, reachable only
      // by typing the URL.
      if (kDebugMode)
        GoRoute(
          path: '/debug/db',
          name: 'debug-db',
          builder: (context, state) =>
              DebugSyncScreen(session: AppSession.instance.service),
        ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

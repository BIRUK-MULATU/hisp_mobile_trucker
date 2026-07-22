# Routing

## go_router with a live auth guard

`lib/core/router/app_router.dart`, `go_router: ^14.2.7`. Three named routes:

```dart
static const String login = '/login';
static const String home = '/home';
static const String settings = '/settings';
```

```dart
static final GoRouter router = GoRouter(
  initialLocation: login,
  debugLogDiagnostics: kDebugMode,
  refreshListenable: AppSession.instance,
  redirect: (context, state) {
    final loggedIn = AppSession.instance.isLoggedIn;
    final goingToLogin = state.matchedLocation == login;
    if (!loggedIn && !goingToLogin) return login;
    if (loggedIn && goingToLogin) return home;
    return null;
  },
  routes: [
    GoRoute(path: login, name: 'login', builder: (context, state) => LoginPage(
      sessionExpired: state.uri.queryParameters['reason'] == 'session-expired',
    )),
    GoRoute(path: home, name: 'home', builder: (context, state) => const HomePage()),
    GoRoute(path: settings, name: 'settings', builder: (context, state) => const SettingsPage()),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);
```

`AppSession` (`lib/core/auth/app_session.dart`) is a `ChangeNotifier` singleton wrapping
`SessionService`. As `refreshListenable`, go_router **automatically re-runs `redirect`**
every time `AppSession.sessionChanged()` is called — which happens after every successful
login, logout, and 401. There is no manual `context.go()` call needed anywhere in the app
purely to enforce the auth boundary; the guard is reactive by construction.

The `?reason=session-expired` query parameter is how `AuthInterceptor`'s 401 handler
communicates *why* the user landed back on the login screen, so `LoginPage` can show an
appropriate message instead of a bare, unexplained login form.

## What's deliberately NOT in the route table

Detail flows — dataset selection, section/period pickers, the data entry form itself — are
pushed with plain `Navigator.push(context, MaterialPageRoute(...))`, not declared as
`GoRoute`s. This is called out explicitly in a code comment in `app_router.dart`. The
reasoning: these are linear, stack-based drill-down flows where standard Material back-stack
semantics are exactly what's wanted, and adding them as named routes would mean either deep
GoRoute nesting or juggling a lot of query-parameter state through the URL for no real
benefit (this app has no requirement for deep-linkable intermediate screens). If you're
adding a new top-level destination that needs its own guarded URL (e.g. reachable from a
notification or a deep link), add it as a `GoRoute`; if you're adding another step in an
existing drill-down flow, use `Navigator.push` to match the surrounding pattern.

## Navigation triggers

- Programmatic, post-auth-state-change: `context.go(AppRouter.home)` (from `AuthBloc`
  listeners).
- Drawer / settings navigation: `context.push(AppRouter.settings)` (keeps Home on the stack
  underneath).
- Logout: `context.go(AppRouter.login)` after `LogoutUseCase(...).call()` completes — note
  this is a direct call, not reliant on the auth guard alone, since the guard only
  re-evaluates on the *next* navigation attempt and logout should feel immediate.

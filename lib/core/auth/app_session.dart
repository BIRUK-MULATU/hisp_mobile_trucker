import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'session_service.dart';

/// App-wide holder for the single [SessionService] instance.
///
/// The backend layer deliberately leaves wiring to the app: the session
/// (and its per-user database handle) must be shared by every feature,
/// so it lives here as a singleton. As a [ChangeNotifier] it doubles as
/// the router's `refreshListenable` — call [sessionChanged] after any
/// login/logout so route guards re-evaluate.
class AppSession extends ChangeNotifier {
  AppSession._();
  static final AppSession instance = AppSession._();

  final SessionService service = SessionService();

  /// Server-root API client for the backend sync services
  /// (DataValueSync, CompletenessSync, MetadataSyncService). Set on
  /// every successful login — including OFFLINE logins, since the
  /// verifier only accepts the real credentials, so queued data can be
  /// pushed the moment connectivity returns. Cleared on logout/401.
  ///
  /// Distinct from the legacy ApiClient() singleton, whose base URL
  /// already contains /api while the sync services prepend it.
  ApiClient? api;

  bool get isLoggedIn => service.isLoggedIn;

  /// True when the last session start flagged a backwards clock jump.
  /// UI contract (from PeriodAccess): warn and refuse past-period entry.
  bool get clockTampered => service.clockTampered;

  void sessionChanged() => notifyListeners();
}

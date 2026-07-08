import 'package:flutter/foundation.dart';

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

  bool get isLoggedIn => service.isLoggedIn;

  /// True when the last session start flagged a backwards clock jump.
  /// UI contract (from PeriodAccess): warn and refuse past-period entry.
  bool get clockTampered => service.clockTampered;

  void sessionChanged() => notifyListeners();
}

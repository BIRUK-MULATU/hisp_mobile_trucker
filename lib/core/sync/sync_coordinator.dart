import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/app_session.dart';
import '../network/network_info.dart';
import 'sync_manager.dart';

/// Pushes queued offline writes whenever the app "comes online" —
/// which has three doors, not one:
///
///  1. connectivity returns while the app is running (offline→online),
///  2. the user logs in while already connected (a previous offline
///     session may have left queued work — no transition ever fires),
///  3. a heartbeat retry, for pushes that failed on a link that LOOKS
///     connected (captive portal, flaky network) and would otherwise
///     wait for the next event forever.
///
/// pushPending itself is idempotent and no-ops while logged out, so
/// firing it from every door is safe. Started once in `main()`.
class SyncCoordinator {
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;

  static const _heartbeat = Duration(minutes: 5);

  StreamSubscription<bool>? _subscription;
  Timer? _timer;
  bool _wasConnected = true;
  bool _wasLoggedIn = false;

  SyncCoordinator({
    required NetworkInfo networkInfo,
    required SyncManager syncManager,
  })  : _networkInfo = networkInfo,
        _syncManager = syncManager;

  void start() {
    // Door 1: offline → online transition.
    _subscription ??=
        _networkInfo.onConnectivityChanged.listen((connected) async {
      final cameBackOnline = connected && !_wasConnected;
      _wasConnected = connected;
      if (cameBackOnline) await _pushIfOnline();
    });

    // Door 2: logged-out → logged-in edge (online or offline login —
    // pushIfOnline checks connectivity itself).
    _wasLoggedIn = AppSession.instance.isLoggedIn;
    AppSession.instance.addListener(_onSessionChanged);

    // Door 3: heartbeat retry for queued work behind a dead-but-
    // connected link. Cheap when the queue is empty.
    _timer ??= Timer.periodic(_heartbeat, (_) => _pushIfOnline());
  }

  void _onSessionChanged() {
    final loggedIn = AppSession.instance.isLoggedIn;
    final justLoggedIn = loggedIn && !_wasLoggedIn;
    _wasLoggedIn = loggedIn;
    if (justLoggedIn) unawaited(_pushIfOnline());
  }

  Future<void> _pushIfOnline() async {
    try {
      if (!await _networkInfo.isConnected) return;
      await _syncManager.pushPending();
    } catch (e) {
      // Never crash the app because a background sync failed —
      // pending rows stay queued for the next attempt.
      debugPrint('Auto-sync failed: $e');
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    AppSession.instance.removeListener(_onSessionChanged);
  }
}

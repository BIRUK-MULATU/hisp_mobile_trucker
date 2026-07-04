import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/network_info.dart';
import 'sync_manager.dart';

/// Watches connectivity and pushes queued offline writes as soon as
/// the device comes back online. Started once in `main()`.
///
/// With the [NoopSyncManager] this is harmless (push does nothing);
/// when the SQLite-backed engine is injected, auto-sync just works.
class SyncCoordinator {
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;

  StreamSubscription<bool>? _subscription;
  bool _wasConnected = true;

  SyncCoordinator({
    required NetworkInfo networkInfo,
    required SyncManager syncManager,
  })  : _networkInfo = networkInfo,
        _syncManager = syncManager;

  void start() {
    _subscription ??=
        _networkInfo.onConnectivityChanged.listen((connected) async {
      // Only push on the offline → online transition.
      final cameBackOnline = connected && !_wasConnected;
      _wasConnected = connected;
      if (!cameBackOnline) return;
      try {
        await _syncManager.pushPending();
      } catch (e) {
        // Never crash the app because a background sync failed —
        // pending rows stay queued for the next attempt.
        debugPrint('Auto-sync failed: $e');
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

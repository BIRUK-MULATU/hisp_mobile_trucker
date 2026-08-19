import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/connectivity_service.dart';
import 'repositories/local_visualization_repository_impl.dart';

/// Promotes offline-built chart drafts (ChartConfig.isDraft, saved by
/// ChartBuilderView._saveDraft) into real charts the moment
/// connectivity returns — the same offline→online "door"
/// SyncCoordinator uses for pending data values, scoped to locally
/// saved visualizations instead. Started once in main().
class ChartDraftCoordinator {
  ChartDraftCoordinator._();
  static final ChartDraftCoordinator instance = ChartDraftCoordinator._();

  /// Bumped after a promotion pass that actually promoted something —
  /// Local Dashboard listens to reload itself instead of polling.
  final ValueNotifier<int> tick = ValueNotifier(0);

  bool _wasOnline = true;
  bool _running = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _wasOnline = ConnectivityService.instance.online ?? true;
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    final online = ConnectivityService.instance.online ?? false;
    final cameBackOnline = online && !_wasOnline;
    _wasOnline = online;
    if (cameBackOnline) unawaited(_promote());
  }

  Future<void> _promote() async {
    if (_running) return;
    _running = true;
    try {
      final promoted =
          await LocalVisualizationRepositoryImpl().promotePendingDrafts();
      if (promoted > 0) tick.value++;
    } catch (_) {
      // Never let a background promotion pass crash the app.
    } finally {
      _running = false;
    }
  }
}

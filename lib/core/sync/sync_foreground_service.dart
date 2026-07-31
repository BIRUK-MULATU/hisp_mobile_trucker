import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/// Thin wrapper over the native Android foreground service
/// (android/.../SyncForegroundService.kt) that keeps the app process at
/// foreground priority while a push is in flight, so the OS's
/// background-execution limits (and most OEM battery managers) don't
/// kill it mid-sync once the user leaves the app. Started/stopped by
/// [SyncCoordinator] around each push attempt — never left running
/// with nothing queued, so the notification only appears when there's
/// actually work to protect.
///
/// No-op on every platform except Android: iOS caps background
/// execution at a few seconds regardless of any service-style API, so
/// there's no equivalent worth wiring up there.
class SyncForegroundService {
  static const _channel =
      MethodChannel('com.hisp.hisp_mobile_trucker/sync_foreground_service');

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('start');
    } catch (e) {
      // Best-effort — a failed service start must not block the sync
      // itself; it only means the OS's background kill protection
      // doesn't apply for this attempt.
      log.w('[sync] foreground service start failed: $e');
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      log.w('[sync] foreground service stop failed: $e');
    }
  }
}

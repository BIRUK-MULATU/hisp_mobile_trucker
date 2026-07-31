import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Asks the user to exempt the app from OEM battery optimization, so
/// [SyncForegroundService] actually gets the background-kill protection
/// Android's standard foreground-service contract promises — several
/// OEMs (Xiaomi, Huawei, Samsung, Oppo) kill foreground services anyway
/// unless the app is separately whitelisted. Shown at most once ever,
/// tracked the same way as [OnboardingService]'s one-time flags.
class BatteryOptimization {
  static const _channel =
      MethodChannel('com.hisp.hisp_mobile_trucker/sync_foreground_service');
  static const _promptedKey = 'has_prompted_battery_optimization';

  /// True once the OS already exempts this app — nothing left to ask.
  static Future<bool> isIgnoringOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>(
              'isIgnoringBatteryOptimizations') ??
          false;
    } catch (e) {
      log.w('[sync] battery optimization check failed: $e');
      return true; // fail open — don't nag if we can't even tell.
    }
  }

  /// Fires the OS's own "allow this app to ignore battery optimizations"
  /// dialog. Fire-and-forget: Android doesn't hand back the user's
  /// choice through this intent, so callers re-check
  /// [isIgnoringOptimizations] later if they need to know the outcome.
  static Future<void> requestExemption() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      log.w('[sync] battery optimization request failed: $e');
    }
  }

  /// Whether the one-time prompt has already been shown (or skipped,
  /// or accepted) — checked once after login, on the home screen.
  static Future<bool> hasPrompted() async {
    if (!Platform.isAndroid) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }

  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }
}

package com.hisp.hisp_mobile_trucker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Dart (SyncCoordinator / BatteryOptimization) to the two
 * pieces of native background-reliability plumbing this app needs:
 * starting/stopping [SyncForegroundService] around a push, and asking
 * the OS to exempt the app from battery-optimization killing.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.hisp.hisp_mobile_trucker/sync_foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val intent = Intent(this, SyncForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stop" -> {
                        stopService(Intent(this, SyncForegroundService::class.java))
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (pm.isIgnoringBatteryOptimizations(packageName)) {
                            result.success(true)
                        } else {
                            try {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                        Uri.parse("package:$packageName")
                                    )
                                )
                                // Android hands the user's choice back via the OS
                                // dialog, not this call — callers re-check
                                // isIgnoringBatteryOptimizations afterwards.
                                result.success(false)
                            } catch (e: Exception) {
                                result.error("UNAVAILABLE", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

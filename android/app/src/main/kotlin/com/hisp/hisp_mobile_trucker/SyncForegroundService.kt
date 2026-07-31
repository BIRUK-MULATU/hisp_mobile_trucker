package com.hisp.hisp_mobile_trucker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Keeps this process at foreground priority while a push of queued
 * offline data (data values / completions / charts) is in flight, so
 * Android's background-execution limits — and most OEM battery
 * managers — don't kill the app mid-sync once the user leaves it.
 *
 * Started/stopped from Dart (SyncCoordinator, via the
 * "sync_foreground_service" MethodChannel in MainActivity) around each
 * push attempt only — SyncCoordinator checks SyncManager.hasPendingWork
 * first, so this never runs, and the notification never appears, when
 * there's nothing queued.
 */
class SyncForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "hisp_data_sync"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Data sync",
                    NotificationManager.IMPORTANCE_LOW
                )
                channel.description =
                    "Shown briefly while queued offline data uploads to the server"
                manager.createNotificationChannel(channel)
            }
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("HISP Tracker")
            .setContentText("Syncing offline data…")
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }
}

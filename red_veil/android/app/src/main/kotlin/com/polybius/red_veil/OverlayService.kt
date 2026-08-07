package com.polybius.red_veil

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

/**
 * Draws a translucent cherry-red filter over other apps
 * (TYPE_APPLICATION_OVERLAY) and keeps a foreground notification so the
 * process stays alive while the filter is active.
 */
class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> {
                val intensity = intent.getFloatExtra(EXTRA_INTENSITY, 0.55f)
                startForeground(NOTIF_ID, buildNotification())
                showOverlay(intensity)
            }
            ACTION_UPDATE -> {
                val intensity = intent.getFloatExtra(EXTRA_INTENSITY, 0.55f)
                overlayView?.setBackgroundColor(redColor(intensity))
            }
            ACTION_HIDE -> {
                hideOverlay()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun redColor(intensity: Float): Int {
        val alpha = (intensity.coerceIn(0.15f, 0.85f) * 255).toInt()
        return Color.argb(alpha, 180, 0, 0)
    }

    private fun showOverlay(intensity: Float) {
        if (overlayView != null) {
            overlayView?.setBackgroundColor(redColor(intensity))
            return
        }
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val view = FrameLayout(this).apply {
            setBackgroundColor(redColor(intensity))
            // Let touches pass through to the app underneath.
            // FLAG_NOT_TOUCHABLE is set on the LayoutParams below.
        }
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }
        windowManager?.addView(view, params)
        overlayView = view
    }

    private fun hideOverlay() {
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
    }

    private fun buildNotification(): Notification {
        val channelId = "darth_cherry_overlay"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Darth Cherry",
                NotificationManager.IMPORTANCE_LOW,
            )
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
        val launch = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, channelId)
            .setContentTitle("DARTH CHERRY active")
            .setContentText("Red night filter overlaid — tap to adjust")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(launch)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }

    companion object {
        const val ACTION_SHOW = "com.polybius.red_veil.SHOW"
        const val ACTION_UPDATE = "com.polybius.red_veil.UPDATE"
        const val ACTION_HIDE = "com.polybius.red_veil.HIDE"
        const val EXTRA_INTENSITY = "intensity"
        const val NOTIF_ID = 18766
    }
}

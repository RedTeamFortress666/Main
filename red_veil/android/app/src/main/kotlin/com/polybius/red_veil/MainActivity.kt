package com.polybius.red_veil

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.polybius.red_veil/overlay",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this)
                        else true,
                    )
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "showOverlay" -> {
                    val intensity =
                        ((call.arguments as? Map<*, *>)?.get("intensity") as? Number)
                            ?.toFloat() ?: 0.55f
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_SHOW
                        putExtra(OverlayService.EXTRA_INTENSITY, intensity)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "updateOverlay" -> {
                    val intensity =
                        ((call.arguments as? Map<*, *>)?.get("intensity") as? Number)
                            ?.toFloat() ?: 0.55f
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_UPDATE
                        putExtra(OverlayService.EXTRA_INTENSITY, intensity)
                    }
                    startService(intent)
                    result.success(true)
                }
                "hideOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_HIDE
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

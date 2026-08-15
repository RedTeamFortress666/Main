package com.polybius.doomsday_clock

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "doomsday_clock/packages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPackageInstalled" -> {
                        val pkg = call.argument<String>("package")
                        result.success(!pkg.isNullOrBlank() && isInstalled(pkg))
                    }
                    "launchPolybius" -> {
                        val pkg = call.argument<String>("package")
                            ?: "com.polybius.polybius.user"
                        val activity = call.argument<String>("activity")
                            ?: "com.polybius.polybius.MainActivity"
                        result.success(launchPayload(pkg, activity))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchPayload(packageName: String, activity: String): Boolean {
        if (!isInstalled(packageName)) return false
        return try {
            // Explicit component — Polybius has no LAUNCHER icon.
            val launch = Intent().setClassName(packageName, activity)
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launch)
            true
        } catch (_: Exception) {
            false
        }
    }
}

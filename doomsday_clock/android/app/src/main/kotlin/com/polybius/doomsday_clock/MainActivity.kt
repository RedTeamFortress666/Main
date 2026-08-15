package com.polybius.doomsday_clock

import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
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
                    "launchPackage" -> {
                        val pkg = call.argument<String>("package") ?: ""
                        result.success(pkg.isNotBlank() && launchPackage(pkg))
                    }
                    "routeStatus" -> result.success(routeStatus())
                    "setPrivateDns" -> {
                        val mode = call.argument<String>("mode") ?: "hostname"
                        val host = call.argument<String>("hostname") ?: ""
                        result.success(setPrivateDns(mode, host))
                    }
                    "setRouteFlag" -> {
                        val key = call.argument<String>("key") ?: ""
                        val value = call.argument<Boolean>("value") ?: false
                        result.success(setRouteFlag(key, value))
                    }
                    "applyHardenedProfile" -> result.success(applyHardenedProfile())
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
            val launch = Intent().setClassName(packageName, activity)
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launch)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun launchPackage(packageName: String): Boolean {
        if (!isInstalled(packageName)) return false
        return try {
            val launch = packageManager.getLaunchIntentForPackage(packageName)
                ?: return false
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launch)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun routeStatus(): Map<String, Any> {
        val cr = contentResolver
        val dnsMode = Settings.Global.getString(cr, "private_dns_mode") ?: "off"
        val dnsHost = Settings.Global.getString(cr, "private_dns_specifier") ?: ""
        val mac = Settings.Global.getInt(cr, "wifi_connected_mac_randomization_enabled", 1) == 1
        val wifiScan = Settings.Global.getInt(cr, "wifi_scan_always_enabled", 0) == 1
        val bleScan = Settings.Global.getInt(cr, "ble_scan_always_enabled", 0) == 1
        val loc = Settings.Secure.getInt(cr, Settings.Secure.LOCATION_MODE, 0)
        val captive = Settings.Global.getInt(cr, "captive_portal_mode", 1)
        val vpn = Settings.Secure.getString(cr, "always_on_vpn_app") ?: ""
        val lockdown = Settings.Secure.getInt(cr, "always_on_vpn_lockdown", 0) == 1
        return mapOf(
            "dnsMode" to dnsMode,
            "dnsHost" to dnsHost,
            "macRandom" to mac,
            "wifiScanAlways" to wifiScan,
            "bleScanAlways" to bleScan,
            "locationOff" to (loc == 0),
            "captivePortalOff" to (captive == 0),
            "vpnPackage" to vpn,
            "vpnLockdown" to lockdown,
            "browserRole" to if (isInstalled("com.brave.browser")) "com.brave.browser" else "",
        )
    }

    private fun setPrivateDns(mode: String, hostname: String): Boolean {
        return try {
            Settings.Global.putString(contentResolver, "private_dns_mode", mode)
            if (hostname.isNotBlank()) {
                Settings.Global.putString(contentResolver, "private_dns_specifier", hostname)
            }
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun setRouteFlag(key: String, value: Boolean): Boolean {
        return try {
            val cr = contentResolver
            when (key) {
                "macRandom" -> Settings.Global.putInt(
                    cr, "wifi_connected_mac_randomization_enabled", if (value) 1 else 0
                )
                "wifiScanOff" -> Settings.Global.putInt(
                    cr, "wifi_scan_always_enabled", if (value) 0 else 1
                )
                "bleScanOff" -> Settings.Global.putInt(
                    cr, "ble_scan_always_enabled", if (value) 0 else 1
                )
                "locationOff" -> Settings.Secure.putInt(
                    cr, Settings.Secure.LOCATION_MODE, if (value) 0 else Settings.Secure.LOCATION_MODE_HIGH_ACCURACY
                )
                "captiveOff" -> Settings.Global.putInt(
                    cr, "captive_portal_mode", if (value) 0 else 1
                )
                else -> return false
            }
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun applyHardenedProfile(): Boolean {
        var ok = setPrivateDns("hostname", "dns.quad9.net")
        ok = setRouteFlag("macRandom", true) && ok
        ok = setRouteFlag("wifiScanOff", true) && ok
        ok = setRouteFlag("bleScanOff", true) && ok
        ok = setRouteFlag("locationOff", true) && ok
        ok = setRouteFlag("captiveOff", true) && ok
        return ok
    }
}

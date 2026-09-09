#!/system/bin/sh
# CRYPT3X OS — idempotent privacy clamps.
# Runs as system after boot_completed. Failures are non-fatal so a missing
# `settings` binary on a stripped tree cannot loop the service.

log -t crypt3x_harden "applying privacy clamps"

put_global() {
  key="$1"
  val="$2"
  settings put global "$key" "$val" 2>/dev/null || \
    cmd settings put global "$key" "$val" 2>/dev/null || true
}

put_secure() {
  key="$1"
  val="$2"
  settings put secure "$key" "$val" 2>/dev/null || \
    cmd settings put secure "$key" "$val" 2>/dev/null || true
}

# Captive portal — do not phone Google.
put_global captive_portal_mode 0
put_global captive_portal_detection_enabled 0
put_global captive_portal_http_url ""
put_global captive_portal_https_url ""
put_global captive_portal_fallback_url ""
put_global captive_portal_other_fallback_urls ""

# Private DNS (DNS-over-TLS) via Quad9. No 8.8.8.8 / dns.google.
put_global private_dns_mode hostname
put_global private_dns_specifier dns.quad9.net

# NTP — pool.ntp.org, not time.android.com.
put_global ntp_server 2.android.pool.ntp.org

# ADB / developer — re-clamp unless the builder set CRYPT3X_DEV_ADB.
# ro.crypt3x.dev_adb is 1 only on those builds.
if [ "$(getprop ro.crypt3x.dev_adb)" != "1" ]; then
  put_global adb_enabled 0
  put_global development_settings_enabled 0
  setprop persist.sys.usb.config none 2>/dev/null || true
  setprop persist.service.adb.enable 0 2>/dev/null || true
fi
put_global adb_wifi_enabled 0
put_global verifier_verify_adb_installs 0
put_global package_verifier_enable 0
put_global send_action_app_error 0

# Radios / location leaks.
put_global ble_scan_always_enabled 0
put_global wifi_scan_always_enabled 0
put_global wifi_wakeup_enabled 0
put_global wifi_networks_available_notification_on 0
put_global assisted_gps_enabled 0
put_secure location_providers_allowed ""

# LineageOS telemetry + USB-while-locked (Trust).
put_global lineageos_stats_collection 0
put_global lineage_stats_collection 0
put_global trust_restrict_usb 1

# Backup / provisioning leftovers.
put_secure backup_enabled 0
put_global device_provisioned 1
put_secure user_setup_complete 1

log -t crypt3x_harden "done"
exit 0

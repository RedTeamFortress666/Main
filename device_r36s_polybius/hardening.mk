# CRYPT3X OS — privacy + security defaults (LineageOS 18.1 / Android 11).
# Source overlays (SettingsProvider / frameworks) are the first-boot layer.
# These properties are fallbacks and apply on every boot via build.prop.
#
# Production lunch: lineage_r36s_crypt3x-user  (release-keys, no ADB).
# Bring-up:         lineage_r36s_crypt3x-userdebug with CRYPT3X_DEV_ADB=true
#                   if you *must* have USB debugging. Never the default.

# ---------------------------------------------------------------------------
# USB / ADB — off unless the builder explicitly opts in
# ---------------------------------------------------------------------------
# persist.sys.usb.config=mtp,adb was the previous default (hostile USB + shell).
ifneq ($(CRYPT3X_DEV_ADB),true)
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=none \
    persist.service.adb.enable=0 \
    persist.adb.notify=1 \
    persist.adb.tcp.port=0 \
    sys.usb.config=none \
    ro.adb.secure=1 \
    ro.secure=1
else
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp,adb \
    persist.service.adb.enable=1 \
    persist.adb.tcp.port=0 \
    ro.adb.secure=1
endif

# ---------------------------------------------------------------------------
# Resolver / captive portal / NTP — no Google endpoints
# Quad9 (9.9.9.9 / dns.quad9.net) is the pre-Private-DNS fallback.
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    net.dns1=9.9.9.9 \
    net.dns2=149.112.112.112 \
    persist.sys.cap_portal=0 \
    captive_portal_mode=0 \
    captive_portal_detection_enabled=0 \
    captive_portal_http_url= \
    captive_portal_https_url= \
    captive_portal_fallback_url= \
    persist.sys.timezone=UTC \
    persist.sys.strictmode.disable=false

# ---------------------------------------------------------------------------
# Identity / telephony leftovers / backup / tracing
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.android.dataroaming=false \
    ro.com.android.wifi-watchlist= \
    ro.com.google.clientidbase= \
    ro.com.google.gmsversion= \
    ro.setupwizard.mode=DISABLED \
    ro.opa.eligible_device=false \
    ro.control_privapp_permissions=enforce \
    persist.traced.enable=0 \
    persist.sys.purgeable_assets=1 \
    profiler.force_disable_ulog=1 \
    profiler.force_disable_err_rpt=1 \
    ro.config.nocheckin=1 \
    persist.sys.unplug.notification=0

# SUPL / A-GPS would otherwise default at supl.google.com.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.gps.lpp=0 \
    persist.sys.gps.assisted=0 \
    ro.gps.agps_provider=0

# LineageOS statistics + updater phone-home (also stripped as packages).
PRODUCT_PROPERTY_OVERRIDES += \
    persist.lineage.stats_disabled=1 \
    lineage.updater.force_off=1

# ---------------------------------------------------------------------------
# Product flags consumed by init.crypt3x.rc / vault
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    ro.polybius.product=1 \
    ro.crypt3x.product=1 \
    ro.crypt3x.harden=1 \
    ro.crypt3x.zero_telemetry=1 \
    ro.polybius.bridge.port=17312 \
    ro.crypt3x.dns=dns.quad9.net \
    ro.crypt3x.ntp=2.android.pool.ntp.org \
    ro.crypt3x.browser=org.cromite.cromite

# ---------------------------------------------------------------------------
# RAM — common already sets low_ram / no Scudo / Go ART
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=true \
    dalvik.vm.heapsize=192m \
    dalvik.vm.heapgrowthlimit=96m \
    persist.sys.zram_enabled=1

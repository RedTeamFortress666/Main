# CRYPT3X OS — Android 11 (2026) lightweight hardening.
# Overlay + SettingsProvider defaults are the adaptable layer; these
# properties are first-boot fallbacks if Private DNS is not up yet.

# Resolver fallback (used before Private DNS / VPN). Quad9, not Google.
PRODUCT_PROPERTY_OVERRIDES += \
    net.dns1=9.9.9.9 \
    net.dns2=149.112.112.112 \
    persist.sys.usb.config=mtp,adb \
    persist.adb.tcp.port=0 \
    ro.adb.secure=1 \
    persist.sys.strictmode.disable=true \
    ro.com.android.dataroaming=false \
    persist.sys.cap_portal=0

# Captive portal: do not phone Google. 0 = ignore (Settings.Global.CAPTIVE_PORTAL_MODE).
PRODUCT_PROPERTY_OVERRIDES += \
    captive_portal_mode=0 \
    captive_portal_http_url= \
    captive_portal_https_url=

PRODUCT_PROPERTY_OVERRIDES += \
    ro.polybius.product=1 \
    ro.crypt3x.product=1 \
    ro.crypt3x.harden=1 \
    ro.polybius.bridge.port=17312 \
    ro.crypt3x.dns=dns.quad9.net \
    ro.crypt3x.browser=com.brave.browser

# Keep the image small. common already sets low_ram / no Scudo / Go ART.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=true \
    dalvik.vm.heapsize=192m \
    dalvik.vm.heapgrowthlimit=96m \
    persist.sys.zram_enabled=1 \
    debug.sf.nobootanimation=0

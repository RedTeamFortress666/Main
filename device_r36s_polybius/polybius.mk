# Product overlay for lineage_r36s_polybius.
# Hardware HALs, firmware, audio, Wi-Fi, BT, and panel support stay in
# device/gameconsole/common + device/gameconsole/r36s.

POLYBIUS_DEVICE_PATH := device/gameconsole/r36s

# ---------------------------------------------------------------------------
# Overlays (defaults, USB, home)
# ---------------------------------------------------------------------------
DEVICE_PACKAGE_OVERLAYS += $(POLYBIUS_DEVICE_PATH)/polybius_overlay

# ---------------------------------------------------------------------------
# Preinstalled apps (APKs are optional; drop them under prebuilts/<Name>/)
# ---------------------------------------------------------------------------
ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/DoomsdayClock/DoomsdayClock.apk),)
PRODUCT_PACKAGES += DoomsdayClock
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/Polybius/Polybius.apk),)
PRODUCT_PACKAGES += Polybius
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/Orbot/Orbot.apk),)
PRODUCT_PACKAGES += Orbot
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/WireGuard/WireGuard.apk),)
PRODUCT_PACKAGES += WireGuard
endif

# File manager for USB OTG storage (APK already lives in common/apps/Files)
PRODUCT_PACKAGES += Files

# Keep Cromite from common/device.mk (already PRODUCT_PACKAGES += Cromite).
# Do not add Jelly / Browser / Chrome.

# ---------------------------------------------------------------------------
# Strip stock AndR36oid extras that fight a covert, low-RAM image
# ---------------------------------------------------------------------------
PRODUCT_PACKAGES += \
    remove-Daijishou \
    remove-Gallery2 \
    remove-Music \
    remove-Eleven \
    remove-Recorder \
    remove-Camera2 \
    remove-Snap \
    remove-PhotoTable \
    remove-WallpaperPicker \
    remove-LiveWallpapersPicker \
    remove-QuickSearchBox \
    remove-Exchange2 \
    remove-PrintSpooler \
    remove-BuiltInPrintService \
    remove-MatLog \
    remove-Jelly \
    remove-Browser2 \
    remove-Email \
    remove-Calendar \
    remove-Etar \
    remove-Contacts \
    remove-DeskClock

# Vault is a standalone front — do not restore AOSP Calendar/Etar.
# Keep CalendarProvider only if the vault APK uses CalendarContract.
# Default: leave common's remove-CalendarProvider in place.

# Never pull Play services even if someone drops vendor/gapps into the tree.
PRODUCT_PACKAGES += \
    remove-GmsCore \
    remove-Phonesky \
    remove-GoogleServicesFramework \
    remove-GoogleContactsSyncAdapter \
    remove-GoogleCalendarSyncAdapter \
    remove-Wellbeing \
    remove-Velvet

# ---------------------------------------------------------------------------
# Mesh / radio / USB host — permissions already in common; reinforce here
# ---------------------------------------------------------------------------
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    $(POLYBIUS_DEVICE_PATH)/permissions/privapp-permissions-polybius.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-polybius.xml \
    $(POLYBIUS_DEVICE_PATH)/permissions/polybius-usb-filter.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/polybius/usb-filter.xml

# ---------------------------------------------------------------------------
# Local WebSocket bridge (disabled until /system/bin/polybius_bridge exists)
# ---------------------------------------------------------------------------
PRODUCT_COPY_FILES += \
    $(POLYBIUS_DEVICE_PATH)/rootdir/init.polybius.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.polybius.rc \
    $(POLYBIUS_DEVICE_PATH)/scripts/polybius_bridge.py:$(TARGET_COPY_OUT_SYSTEM)/etc/polybius/polybius_bridge.py

# ---------------------------------------------------------------------------
# Privacy / network defaults (Orbot VPN mode is the all-traffic Tor path)
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp,adb \
    persist.adb.tcp.port=0 \
    net.dns1=1.1.1.1 \
    net.dns2=9.9.9.9 \
    ro.polybius.product=1 \
    ro.crypt3x.product=1 \
    ro.polybius.bridge.port=17312

# Prefer always-on VPN once Orbot or WireGuard is configured by the user.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.strictmode.disable=true

# ---------------------------------------------------------------------------
# Lighten further vs common (common already sets low_ram, no Scudo, Go)
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=true \
    dalvik.vm.heapsize=192m \
    dalvik.vm.heapgrowthlimit=96m \
    persist.sys.zram_enabled=1 \
    debug.sf.nobootanimation=0

# CRYPT3X OS boot animation (gears → keyhole of light → GÅMÊ ØVĒR card).
# Regenerated by media/render_bootanim.py; zip is STORE-compressed PNGs.
ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip),)
PRODUCT_COPY_FILES += \
    $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip \
    $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
endif

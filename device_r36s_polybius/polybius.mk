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

ifneq ($(CRYPT3X_LITE),true)
ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/PolybiusHq/PolybiusHq.apk),)
PRODUCT_PACKAGES += PolybiusHq
endif
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/DarthCherry/DarthCherry.apk),)
PRODUCT_PACKAGES += DarthCherry
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/Orbot/Orbot.apk),)
PRODUCT_PACKAGES += Orbot
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/WireGuard/WireGuard.apk),)
PRODUCT_PACKAGES += WireGuard
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/Brave/Brave.apk),)
PRODUCT_PACKAGES += Brave
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/FDroid/FDroid.apk),)
PRODUCT_PACKAGES += FDroid
endif

ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/prebuilts/ProtonMail/ProtonMail.apk),)
PRODUCT_PACKAGES += ProtonMail
endif

# File manager for USB OTG storage (APK already lives in common/apps/Files)
PRODUCT_PACKAGES += Files

# Brave replaces Cromite as the only browser. Jelly/Browser2 already stripped.

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
    remove-DeskClock \
    remove-Cromite

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
    $(POLYBIUS_DEVICE_PATH)/permissions/polybius-usb-filter.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/polybius/usb-filter.xml \
    $(POLYBIUS_DEVICE_PATH)/sysconfig/crypt3x.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig/crypt3x.xml

# ---------------------------------------------------------------------------
# Local WebSocket bridge (disabled until /system/bin/polybius_bridge exists)
# ---------------------------------------------------------------------------
PRODUCT_COPY_FILES += \
    $(POLYBIUS_DEVICE_PATH)/rootdir/init.polybius.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.polybius.rc \
    $(POLYBIUS_DEVICE_PATH)/scripts/polybius_bridge.py:$(TARGET_COPY_OUT_SYSTEM)/etc/polybius/polybius_bridge.py

# ---------------------------------------------------------------------------
# Privacy / network / fingerprint (Android 11, 2026)
# ---------------------------------------------------------------------------
$(call inherit-product, $(POLYBIUS_DEVICE_PATH)/hardening.mk)

# CRYPT3X OS boot animation (gears → keyhole of light → GÅMÊ ØVĒR card).
# Regenerated by media/render_bootanim.py; zip is STORE-compressed PNGs.
ifneq ($(CRYPT3X_LITE),true)
ifneq ($(wildcard $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip),)
PRODUCT_COPY_FILES += \
    $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip \
    $(POLYBIUS_DEVICE_PATH)/media/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
endif
endif

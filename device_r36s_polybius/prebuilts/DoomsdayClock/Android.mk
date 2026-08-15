LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/DoomsdayClock.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := DoomsdayClock
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRIVILEGED_MODULE := true
# Vault is the visible HOME. This also drops Daijishou from the image.
LOCAL_OVERRIDES_PACKAGES := \
    Daijishou \
    Home \
    TrebuchetQuickStepGo \
    TrebuchetQuickStep \
    Launcher2 \
    Launcher3 \
    Launcher3QuickStep
LOCAL_SRC_FILES := DoomsdayClock.apk
include $(BUILD_PREBUILT)
endif

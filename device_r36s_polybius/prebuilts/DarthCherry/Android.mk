LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/DarthCherry.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := DarthCherry
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := DarthCherry.apk
# Desk app (com.polybius.red_veil). Do not steal HOME.
include $(BUILD_PREBUILT)
endif

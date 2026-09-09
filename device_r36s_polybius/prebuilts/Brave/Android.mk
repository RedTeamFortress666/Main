LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/Brave.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := Brave
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := Brave.apk
# Optional drop-in. Cromite remains default until this APK is present.
LOCAL_OVERRIDES_PACKAGES := Cromite Jelly Browser2
include $(BUILD_PREBUILT)
endif

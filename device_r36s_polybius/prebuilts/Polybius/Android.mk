LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/Polybius.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := Polybius
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
# Not privileged. CAMERA/LOCATION stay runtime-granted, not auto-granted.
LOCAL_SRC_FILES := Polybius.apk
# Operator/user build (com.polybius.polybius.user). Do not steal HOME.
include $(BUILD_PREBUILT)
endif

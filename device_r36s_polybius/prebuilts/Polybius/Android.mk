LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/Polybius.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := Polybius
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := Polybius.apk
# Hidden by the vault (HOME). Do not override other launchers here.
# LOCAL_PRIVILEGED_MODULE := true
include $(BUILD_PREBUILT)
endif

LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/PolybiusHq.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := PolybiusHq
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
# Not privileged. CAMERA/LOCATION stay runtime-granted, not auto-granted.
LOCAL_SRC_FILES := PolybiusHq.apk
include $(BUILD_PREBUILT)
endif

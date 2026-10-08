# CRYPT3X OS lite — under 16GB packed image for a 32GB SD.
# Set the flag before inheriting so HQ + bootanim stay out.

CRYPT3X_LITE := true

$(call inherit-product, device/gameconsole/r36s/lineage_r36s_crypt3x.mk)

PRODUCT_NAME := lineage_r36s_crypt3x_lite
PRODUCT_MODEL := CRYPT3X OS LITE

PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypt3x.lite=1 \
    ro.crypt3x.duress=1

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME="crypt3x_lite" \
    PRIVATE_BUILD_DESC="lineage_r36s_crypt3x_lite-userdebug 11 RP1A.201005.004 test-keys"

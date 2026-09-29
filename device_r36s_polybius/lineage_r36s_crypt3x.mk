# CRYPT3X OS — specialized AndR36oid product for the R36S.
# Inherits the stock lineage_r36s hardware bring-up; do not fork BoardConfig.

$(call inherit-product, device/gameconsole/r36s/lineage_r36s.mk)
$(call inherit-product, device/gameconsole/r36s/polybius.mk)

PRODUCT_NAME := lineage_r36s_crypt3x
PRODUCT_DEVICE := r36s
PRODUCT_BRAND := CRYPT3X
PRODUCT_MODEL := CRYPT3X OS
PRODUCT_MANUFACTURER := GÅMÊ ØVĒR

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE="r36s" \
    PRODUCT_NAME="crypt3x" \
    PRIVATE_BUILD_DESC="lineage_r36s_crypt3x-userdebug 11 RP1A.201005.004 test-keys"

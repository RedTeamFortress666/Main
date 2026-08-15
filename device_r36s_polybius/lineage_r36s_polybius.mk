# Specialized AndR36oid product: Polybius + vault + mesh/privacy, still RK3326/R36S.
# Inherits the stock lineage_r36s hardware bring-up; do not fork BoardConfig.

$(call inherit-product, device/gameconsole/r36s/lineage_r36s.mk)
$(call inherit-product, device/gameconsole/r36s/polybius.mk)

PRODUCT_NAME := lineage_r36s_polybius
PRODUCT_DEVICE := r36s
PRODUCT_MODEL := PØLYBĪUS on GameConsole R36S

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE="r36s" \
    PRODUCT_NAME="r36s_polybius" \
    PRIVATE_BUILD_DESC="lineage_r36s_polybius-userdebug 11 RP1A.201005.004 test-keys"

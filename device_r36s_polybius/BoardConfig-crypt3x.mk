# CRYPT3X board extras. Included from device/gameconsole/r36s/BoardConfig.mk
# by apply.sh (one -include line). Do not fork the rest of BoardConfig.

BOARD_SEPOLICY_DIRS += device/gameconsole/r36s/sepolicy

# RK3326 has no working AVB chain. Do not pretend verified boot exists.
BOARD_AVB_ENABLE := false

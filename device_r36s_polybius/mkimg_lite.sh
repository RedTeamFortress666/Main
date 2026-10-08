#!/bin/bash
# Pack a CRYPT3X lite SD image under 16GB (default 8GiB) for a 32GB card.
# Run from device/gameconsole/r36s as root after:
#   lunch lineage_r36s_crypt3x_lite-userdebug && mka bootimage systemimage
set -euo pipefail

LINEAGEVERSION=lineage-18.1
DATE=$(date -u +%Y%m%d)
TIME=$(date -u +%H%M)
DEVICE=r36s-crypt3x-lite
IMGNAME=$LINEAGEVERSION-$DATE-$TIME-$DEVICE.img
IMGSIZE="${CRYPT3X_LITE_IMGSIZE:-8}"   # GiB — must stay < 16
OUTDIR=${ANDROID_PRODUCT_OUT:="../../../out/target/product/r36s"}

if [ "$IMGSIZE" -ge 16 ]; then
    echo "Lite image must be under 16GiB (got ${IMGSIZE}G)." >&2
    exit 1
fi

# Reuse the stock packer for BOOT + system, then grow the file to IMGSIZE
# so the card has a defined <16GB footprint. Userdata is created on first boot
# from the unused tail of this image, not the whole 32GB card, until resize.
export IMGNAME DEVICE
# shellcheck disable=SC1091
if [ -f ./mkimg.sh ]; then
    # Stock script hardcodes IMGSIZE=3 and DEVICE. Call it, then pad.
    bash ./mkimg.sh
    STOCK=$(ls -1t lineage-18.1-*-r36s-android.img 2>/dev/null | head -1 || true)
    if [ -n "$STOCK" ] && [ -f "$STOCK" ]; then
        truncate -s "${IMGSIZE}G" "$STOCK"
        mv "$STOCK" "$IMGNAME"
        echo "Padded $IMGNAME to ${IMGSIZE}GiB (under 16GiB lite cap)."
        zip -r -q "$IMGNAME.zip" "$IMGNAME"
        echo "Packaged $IMGNAME.zip"
        exit 0
    fi
fi

echo "mkimg.sh did not produce a stock image; see device/gameconsole/r36s/mkimg.sh" >&2
exit 1

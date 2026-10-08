#!/usr/bin/env bash
# Assemble CRYPT3X_ETCHER/ from the 12 zip parts — same layout the phone
# flasher writes for balenaEtcher / Rufus.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-.}"
OUT_DIR="${2:-$DIR/CRYPT3X_ETCHER}"
ZIP_NAME="CRYPT3X_OS_LITE-r36s-20260815.zip"
IMG_NAME="lineage-18.1-20260815-1244-r36s-crypt3x-lite.img"

mkdir -p "$OUT_DIR"
"$SCRIPT_DIR/assemble-crypt3x-lite-zip.sh" "$DIR" "$OUT_DIR/$ZIP_NAME"
SHA="$(sha256sum "$OUT_DIR/$ZIP_NAME" | awk '{print $1}')"
BYTES="$(stat -c '%s' "$OUT_DIR/$ZIP_NAME")"

cat > "$OUT_DIR/ETCHER.txt" <<EOF
CRYPT3X OS LITE — balenaEtcher / Raspberry Pi Imager
====================================================

This folder was assembled from part00–part11.

1. Open balenaEtcher (or Raspberry Pi Imager).
2. Flash from file: $ZIP_NAME
   (If Etcher refuses extra .txt files inside the kit zip, unzip first
   and select $IMG_NAME.)
3. Select the R36S microSD (32 GB or larger). Confirm.
4. Flash. Eject. Power the handheld OFF, seat the card in the OS slot,
   power on. First boot can take a few minutes.

Do not copy $IMG_NAME onto a formatted card. That is not a flash.
This erases the entire microSD.
EOF

cat > "$OUT_DIR/RUFUS.txt" <<EOF
CRYPT3X OS LITE — Rufus (Windows)
=================================

1. Unzip $ZIP_NAME onto a disk with >9 GiB free (NTFS or exFAT).
   FAT32 cannot store the 8 GiB .img (4 GiB file cap).
2. Open Rufus. Select the microSD.
3. Boot selection: Disk or ISO image → $IMG_NAME
4. Image mode: DD Image (not ISO). Write. Eject.

Do not use ISO mode. This is a GPT disk image, not a CD ISO.
EOF

cat > "$OUT_DIR/FLASH.txt" <<EOF
# CRYPT3X OS LITE — flash the R36S SD
# WARNING: this erases the target device.

unzip -o $ZIP_NAME
sudo dd if=$IMG_NAME of=/dev/sdX bs=4M status=progress conv=fsync
sync

Or from the repo:
  polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX

balenaEtcher / Raspberry Pi Imager: select $ZIP_NAME or $IMG_NAME.
Rufus: $IMG_NAME in DD Image mode.
EOF

printf '%s  %s\n' "$SHA" "$ZIP_NAME" > "$OUT_DIR/SHA256.txt"
cat > "$OUT_DIR/CRYPT3X_ETCHER_READY.txt" <<EOF
CRYPT3X OS LITE Etcher/Rufus kit ready.
file=$ZIP_NAME
bytes=$BYTES
sha256=$SHA
folder=CRYPT3X_ETCHER
etcher=select $ZIP_NAME (or unzip and select the .img)
rufus=unzip then DD Image mode on the .img
EOF

echo "OK $OUT_DIR ($BYTES bytes)"
echo "$SHA"

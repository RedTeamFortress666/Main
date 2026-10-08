#!/usr/bin/env bash
# Flash the official 8 GiB CRYPT3X OS lite GPT image to a block device.
# Does not invent a path — searches known build outputs, then argv.
set -euo pipefail

IMG_NAME="lineage-18.1-20260815-1244-r36s-crypt3x-lite.img"
EXPECT_SHA="ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc"
EXPECT_BYTES=8589934592

usage() {
  cat <<EOF
Usage: $0 /dev/sdX [path-to-img]

Writes the CRYPT3X OS lite 8 GiB image with dd after SHA-256 + size checks.
THIS ERASES THE TARGET DEVICE.

Searches, in order:
  \$CRYPT3X_LITE_IMG
  \$2 (optional image path)
  polybius_flasher/images/$IMG_NAME
  /opt/android/andr36oid/device/gameconsole/r36s/$IMG_NAME
EOF
  exit 1
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage
[[ $# -lt 1 ]] && usage

DEST="$1"
shift || true
CANDIDATE="${1:-${CRYPT3X_LITE_IMG:-}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

find_img() {
  local p
  for p in \
    "$CANDIDATE" \
    "$ROOT/images/$IMG_NAME" \
    "/opt/android/andr36oid/device/gameconsole/r36s/$IMG_NAME"
  do
    if [[ -n "$p" && -f "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

IMG="$(find_img)" || {
  echo "CRYPT3X lite image not found. Set CRYPT3X_LITE_IMG or pass the .img path." >&2
  exit 2
}

if [[ ! -b "$DEST" ]]; then
  echo "Not a block device: $DEST" >&2
  exit 3
fi

BYTES="$(stat -c '%s' "$IMG")"
if [[ "$BYTES" -ne "$EXPECT_BYTES" ]]; then
  echo "Size mismatch: $IMG is $BYTES bytes, expected $EXPECT_BYTES" >&2
  exit 4
fi

echo "Verifying SHA-256 of $IMG ($BYTES bytes)…"
GOT="$(sha256sum "$IMG" | awk '{print $1}')"
if [[ "$GOT" != "$EXPECT_SHA" ]]; then
  echo "SHA-256 mismatch:" >&2
  echo "  expected $EXPECT_SHA" >&2
  echo "  actual   $GOT" >&2
  exit 5
fi

echo "Image OK. About to write:"
echo "  if=$IMG"
echo "  of=$DEST"
echo "This destroys all data on $DEST."
read -r -p "Type FLASH to continue: " confirm
[[ "$confirm" == "FLASH" ]] || { echo "Aborted."; exit 6; }

sudo dd if="$IMG" of="$DEST" bs=4M status=progress conv=fsync
sync
echo "Done. Eject $DEST and boot the R36S from this card."

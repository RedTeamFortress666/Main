#!/usr/bin/env bash
# Copy this product overlay into the live AndR36oid device tree and apply
# the USB ACM/serial kernel fragment.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius"
DT="$ROOT/device/gameconsole/r36s"
KERNEL_DEFCONFIG="$ROOT/kernel/gameconsole/r36s/arch/arm64/configs/lineageos_r36s_defconfig"
UEVENTD="$ROOT/device/gameconsole/common/ueventd.rk30board.rc"

if [[ ! -d "$DT" ]]; then
  echo "Device tree not found at $DT" >&2
  echo "Clone android_device_gameconsole_r36s first (see ANDR36OID.md)." >&2
  exit 1
fi

copy_into_dt() {
  local rel="$1"
  mkdir -p "$(dirname "$DT/$rel")"
  cp -a "$SRC/$rel" "$DT/$rel"
}

copy_into_dt AndroidProducts.mk
copy_into_dt lineage_r36s_polybius.mk
copy_into_dt polybius.mk
copy_into_dt permissions
copy_into_dt polybius_overlay
copy_into_dt prebuilts
copy_into_dt rootdir
copy_into_dt scripts

echo "Installed product files into $DT"

if [[ -f "$KERNEL_DEFCONFIG" ]]; then
  python3 - "$KERNEL_DEFCONFIG" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text()
replacements = {
    "# CONFIG_USB_ACM is not set": "CONFIG_USB_ACM=y",
    "# CONFIG_USB_SERIAL is not set": "CONFIG_USB_SERIAL=y\nCONFIG_USB_SERIAL_GENERIC=y\nCONFIG_USB_SERIAL_FTDI_SIO=y\nCONFIG_USB_SERIAL_CP210X=y\nCONFIG_USB_SERIAL_CH341=y",
    "# CONFIG_HID_MULTITOUCH is not set": "CONFIG_HID_MULTITOUCH=y",
}
changed = False
for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new, 1)
        changed = True
    elif new.split("\n")[0] in text:
        pass
    else:
        print(f"warning: pattern not found: {old}", file=sys.stderr)
if changed:
    p.write_text(text)
    print(f"Updated {p}")
else:
    print(f"Kernel defconfig already has USB ACM/serial fragments")
PY
else
  echo "Kernel defconfig not found; skip USB ACM patch ($KERNEL_DEFCONFIG)"
fi

if [[ -f "$UEVENTD" ]] && ! grep -q 'ttyACM' "$UEVENTD"; then
  cat >> "$UEVENTD" <<'EOF'

# Polybius / ESP32-S3 LoRa (CDC ACM + USB-UART)
/dev/ttyACM*              0660   system     system
/dev/ttyUSB*              0660   system     system
/dev/hidraw*              0666   system     system
EOF
  echo "Appended ACM/USB-UART nodes to $UEVENTD"
else
  echo "ueventd already has ttyACM or file missing; skip"
fi

echo "Done. Lunch target: lineage_r36s_polybius-userdebug"
echo "Drop APKs under $DT/prebuilts/{Polybius,DoomsdayClock,Orbot,WireGuard}/"

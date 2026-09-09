#!/usr/bin/env bash
# Copy this product overlay into the live AndR36oid device tree and apply
# the USB ACM/serial + kernel hardening fragments.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius"
ANDROID_ROOT="${ANDROID_ROOT:-$ROOT}"
DT="$ANDROID_ROOT/device/gameconsole/r36s"
KERNEL_DEFCONFIG="$ANDROID_ROOT/kernel/gameconsole/r36s/arch/arm64/configs/lineageos_r36s_defconfig"
UEVENTD="$ANDROID_ROOT/device/gameconsole/common/ueventd.rk30board.rc"
BOARDCFG="$DT/BoardConfig.mk"
LOCAL_MANIFESTS="$ANDROID_ROOT/.repo/local_manifests"

if [[ ! -d "$DT" ]]; then
  echo "Device tree not found at $DT" >&2
  echo "Clone android_device_gameconsole_r36s first (see ANDR36OID.md)." >&2
  echo "Or set ANDROID_ROOT to the AndR36oid tree (mka-lite.sh uses /opt/android/andr36oid)." >&2
  exit 1
fi

copy_into_dt() {
  local rel="$1"
  if [[ -d "$SRC/$rel" ]]; then
    mkdir -p "$DT/$rel"
    cp -a "$SRC/$rel"/. "$DT/$rel"/
  else
    mkdir -p "$(dirname "$DT/$rel")"
    cp -a "$SRC/$rel" "$DT/$rel"
  fi
}

copy_into_dt AndroidProducts.mk
copy_into_dt lineage_r36s_crypt3x.mk
copy_into_dt lineage_r36s_crypt3x_lite.mk
copy_into_dt lineage_r36s_polybius.mk
copy_into_dt polybius.mk
copy_into_dt mkimg_lite.sh
copy_into_dt hardening.mk
copy_into_dt BoardConfig-crypt3x.mk
copy_into_dt permissions
copy_into_dt sysconfig
copy_into_dt polybius_overlay
copy_into_dt prebuilts
copy_into_dt rootdir
copy_into_dt scripts
copy_into_dt sepolicy
copy_into_dt network
copy_into_dt kernel
copy_into_dt media/crypt3x_crest.png
copy_into_dt media/render_bootanim.py
if [[ -f "$SRC/media/bootanimation.zip" ]]; then
  copy_into_dt media/bootanimation.zip
fi

chmod 0755 "$DT/rootdir/harden.sh" 2>/dev/null || true

echo "Installed product files into $DT"

if [[ -f "$BOARDCFG" ]] && ! grep -q 'BoardConfig-crypt3x.mk' "$BOARDCFG"; then
  printf '\n# CRYPT3X sepolicy / AVB flags\n-include device/gameconsole/r36s/BoardConfig-crypt3x.mk\n' >> "$BOARDCFG"
  echo "Included BoardConfig-crypt3x.mk from $BOARDCFG"
fi

if [[ -d "$ANDROID_ROOT/.repo" ]]; then
  mkdir -p "$LOCAL_MANIFESTS"
  cp -a "$SRC/local_manifests/crypt3x.xml" "$LOCAL_MANIFESTS/crypt3x.xml"
  echo "Installed local manifest $LOCAL_MANIFESTS/crypt3x.xml"
  # untrack.xml is opt-in: only copy when every remove-project exists.
  if [[ -f "$SRC/local_manifests/untrack.xml" && -x "$(command -v repo || true)" ]]; then
    echo "Note: local_manifests/untrack.xml is NOT copied automatically (repo sync fails on unknown remove-project)."
  fi
fi

if [[ -f "$KERNEL_DEFCONFIG" ]]; then
  python3 - "$KERNEL_DEFCONFIG" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text()
replacements = {
    "# CONFIG_USB_ACM is not set": "CONFIG_USB_ACM=y",
    "# CONFIG_USB_SERIAL is not set": "CONFIG_USB_SERIAL=y\nCONFIG_USB_SERIAL_GENERIC=y\nCONFIG_USB_SERIAL_FTDI_SIO=y\nCONFIG_USB_SERIAL_CP210X=y\nCONFIG_USB_SERIAL_CH341=y",
    "# CONFIG_HID_MULTITOUCH is not set": "CONFIG_HID_MULTITOUCH=y",
    "# CONFIG_SYN_COOKIES is not set": "CONFIG_SYN_COOKIES=y",
    "# CONFIG_SECURITY_DMESG_RESTRICT is not set": "CONFIG_SECURITY_DMESG_RESTRICT=y",
    "CONFIG_DEVMEM=y": "# CONFIG_DEVMEM is not set",
    "CONFIG_DEVKMEM=y": "# CONFIG_DEVKMEM is not set",
    "CONFIG_PROC_KCORE=y": "# CONFIG_PROC_KCORE is not set",
    "CONFIG_KEXEC=y": "# CONFIG_KEXEC is not set",
    "CONFIG_MAGIC_SYSRQ=y": "# CONFIG_MAGIC_SYSRQ is not set",
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
    print("Kernel defconfig already has USB ACM/serial + hardening fragments")
PY
else
  echo "Kernel defconfig not found; skip USB ACM patch ($KERNEL_DEFCONFIG)"
fi

if [[ -f "$UEVENTD" ]]; then
  # Never grant world-writable hidraw (keylog / inject). Strip a previous apply.
  if grep -q 'hidraw' "$UEVENTD"; then
    tmp="$(mktemp)"
    grep -v 'hidraw' "$UEVENTD" > "$tmp"
    mv "$tmp" "$UEVENTD"
    echo "Removed world-accessible hidraw nodes from $UEVENTD"
  fi
  if ! grep -q 'ttyACM' "$UEVENTD"; then
    cat >> "$UEVENTD" <<'EOF'

# CRYPT3X / ESP32-S3 LoRa (CDC ACM + USB-UART). 0660 system — not world.
/dev/ttyACM*              0660   system     system
/dev/ttyUSB*              0660   system     system
EOF
    echo "Appended ACM/USB-UART nodes to $UEVENTD"
  else
    echo "ueventd already has ttyACM; skip"
  fi
else
  echo "ueventd missing; skip ($UEVENTD)"
fi

echo "Done. Production lunch: lineage_r36s_crypt3x-user"
echo "Bring-up (ADB still off unless CRYPT3X_DEV_ADB=true): lineage_r36s_crypt3x-userdebug"
echo "Drop APKs under $DT/prebuilts/{Polybius,DoomsdayClock,FDroid,ProtonMail,DarthCherry}/"
chmod +x "$DT/mkimg_lite.sh" 2>/dev/null || true
echo "Boot animation: $DT/media/bootanimation.zip (python3 device_r36s_polybius/media/render_bootanim.py to rebuild)"

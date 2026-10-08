#!/usr/bin/env bash
# Build a sideload kit for on-device R36S testing without a full ROM compile.
# Target: APK set well under 16GB (budget 2GB of payloads).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius/prebuilts"
DEST="${1:-$ROOT/dist/crypt3x-lite-r36s}"
BUDGET_BYTES=$((2 * 1024 * 1024 * 1024))

rm -rf "$DEST"
mkdir -p "$DEST/apks"

copy_apk() {
  local src="$1"
  local name="$2"
  if [[ -f "$src" ]]; then
    cp -a "$src" "$DEST/apks/$name"
    echo "  $name  $(du -h "$DEST/apks/$name" | awk '{print $1}')"
  else
    echo "  MISSING $src" >&2
  fi
}

echo "CRYPT3X lite testkit → $DEST"
copy_apk "$SRC/DoomsdayClock/DoomsdayClock.apk" DoomsdayClock.apk
copy_apk "$SRC/Polybius/Polybius.apk" Polybius.apk
copy_apk "$SRC/Brave/Brave.apk" Brave.apk
copy_apk "$SRC/FDroid/FDroid.apk" FDroid.apk
copy_apk "$SRC/ProtonMail/ProtonMail.apk" ProtonMail.apk
copy_apk "$SRC/DarthCherry/DarthCherry.apk" DarthCherry.apk
# Lite skips PolybiusHq and bootanimation.zip

TOTAL=$(du -sb "$DEST/apks" | awk '{print $1}')
echo "APK total: $(du -sh "$DEST/apks" | awk '{print $1}') ($TOTAL bytes)"
if [[ "$TOTAL" -gt "$BUDGET_BYTES" ]]; then
  echo "Lite kit exceeds 2GB APK budget." >&2
  exit 1
fi

cat > "$DEST/install-on-device.sh" <<'EOF'
#!/usr/bin/env bash
# Sideload the CRYPT3X lite desk onto a running AndR36oid / CRYPT3X device.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
adb wait-for-device
for apk in "$HERE"/apks/*.apk; do
  echo "install $apk"
  adb install -r -g "$apk" || adb install -r "$apk"
done
echo "Done. HOME is the vault desk (Mail / F-Droid / Brave / Cherry)."
echo "Operator lock → vault. Duress PIN factory-resets userdata."
EOF
chmod +x "$DEST/install-on-device.sh"

cat > "$DEST/README.txt" <<'EOF'
CRYPT3X OS LITE — R36S on-device test kit
=========================================

Packed image (after a Lineage build) is 8GiB, under the 16GiB cap for a
32GB SD. Lunch:

  ./device_r36s_polybius/apply.sh
  lunch lineage_r36s_crypt3x_lite-userdebug
  mka bootimage systemimage
  cd device/gameconsole/r36s && sudo ./mkimg_lite.sh
  sudo dd if=lineage-18.1-*-r36s-crypt3x-lite.img of=/dev/sdX bs=4M status=progress

This folder is the sideload path if you already have AndR36oid on the card:

  ./install-on-device.sh

Desk: Proton Mail, F-Droid, Brave, Darth Cherry.
Polybius user is preinstalled but has no launcher icon.
Polybius HQ and the boot animation are omitted to stay light.

Duress PIN (factory default): 737380
Enter it in the vault lock PIN field. The UI shows ACCESS DENIED, then
userdata is wiped (system partition stays). Change it at first vault setup.
EOF

ARCHIVE="$DEST.tar"
tar -C "$(dirname "$DEST")" -cf "$ARCHIVE" "$(basename "$DEST")"
echo "Wrote $ARCHIVE ($(du -h "$ARCHIVE" | awk '{print $1}'))"
if [[ -d /opt/cursor/artifacts ]]; then
  if cp -a "$ARCHIVE" /opt/cursor/artifacts/crypt3x-lite-r36s-testkit.tar; then
    echo "Copied to /opt/cursor/artifacts/crypt3x-lite-r36s-testkit.tar"
  else
    echo "Skipped artifact copy of the 574MB tar (I/O limit); kit stays at $ARCHIVE"
  fi
fi

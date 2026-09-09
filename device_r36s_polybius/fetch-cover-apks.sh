#!/usr/bin/env bash
# Pull desk cover apps. Cromite is already in AndR36oid — do not replace it
# with Brave unless BRAVE_APK_URL is set (Brave phones home to Google Safe
# Browsing + usage pings).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius/prebuilts"

fetch_url() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  echo "Fetching $url -> $dest"
  curl -fL --retry 4 --retry-delay 4 -o "$dest" "$url"
  file "$dest"
  if ! file "$dest" | grep -qi 'zip\|apk\|java'; then
    echo "warning: $dest may not be an APK" >&2
  fi
}

# Official F-Droid client (suggested stable, not the 2.0 RC).
FDROID_VER="${FDROID_VER:-1023052}"
fetch_url "https://f-droid.org/repo/org.fdroid.fdroid_${FDROID_VER}.apk" \
  "$SRC/FDroid/FDroid.apk"

# Brave is opt-in. Default browser is Cromite (zero Google Safe Browsing).
if [[ -n "${BRAVE_APK_URL:-}" ]]; then
  fetch_url "$BRAVE_APK_URL" "$SRC/Brave/Brave.apk"
else
  echo "Skipping Brave (set BRAVE_APK_URL to override Cromite)."
fi

# Proton Mail: last official GitHub APK (3.0.17). Newer Play builds can replace it.
if [[ -n "${PROTONMAIL_APK_URL:-}" ]]; then
  fetch_url "$PROTONMAIL_APK_URL" "$SRC/ProtonMail/ProtonMail.apk"
else
  echo "Fetching Proton Mail 3.0.17 from ProtonMail/proton-mail-android..."
  mkdir -p "$SRC/ProtonMail"
  gh release download 3.0.17 -R ProtonMail/proton-mail-android \
    -p 'ProtonMail-3.0.17.apk' -D /tmp --clobber
  cp -a /tmp/ProtonMail-3.0.17.apk "$SRC/ProtonMail/ProtonMail.apk"
  file "$SRC/ProtonMail/ProtonMail.apk"
fi

if [[ -d "$ROOT/device/gameconsole/r36s/prebuilts" ]]; then
  echo "Copying cover APKs into live device tree..."
  for pair in FDroid/FDroid.apk Brave/Brave.apk ProtonMail/ProtonMail.apk; do
    if [[ -f "$SRC/$pair" ]]; then
      mkdir -p "$ROOT/device/gameconsole/r36s/prebuilts/$(dirname "$pair")"
      cp -a "$SRC/$pair" "$ROOT/device/gameconsole/r36s/prebuilts/$pair"
    fi
  done
fi

echo "Done. Cover APKs are gitignored. Run scripts/verify-prebuilts.sh if pins exist."

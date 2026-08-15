#!/usr/bin/env bash
# Pull CRYPT3X prebuilt APKs from the v1-stable dist branch via gh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius/prebuilts"
REF="${POLYBIUS_DIST_REF:-cursor/v1-stable-logins-ios-b952}"
REPO="${POLYBIUS_DIST_REPO:-RedTeamFortress666/Main}"

fetch() {
  local remote_path="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  echo "Fetching $remote_path -> $dest"
  gh api -H "Accept: application/vnd.github.raw" \
    "/repos/${REPO}/contents/${remote_path}?ref=${REF}" \
    > "$dest"
  file "$dest"
}

fetch "polybius/dist/polybius-v1-stable-user-android-arm64.apk" \
  "$SRC/Polybius/Polybius.apk"
fetch "polybius/dist/polybius-v1-stable-hq-android-arm64.apk" \
  "$SRC/PolybiusHq/PolybiusHq.apk"
fetch "polybius/dist/doomsday_clock/doomsday-clock-2.0.0-android-arm64.apk" \
  "$SRC/DoomsdayClock/DoomsdayClock.apk"

sha256sum \
  "$SRC/Polybius/Polybius.apk" \
  "$SRC/PolybiusHq/PolybiusHq.apk" \
  "$SRC/DoomsdayClock/DoomsdayClock.apk"

if [[ -d "$ROOT/device/gameconsole/r36s/prebuilts" ]]; then
  echo "Copying into live device tree..."
  cp -a "$SRC/Polybius/Polybius.apk" "$ROOT/device/gameconsole/r36s/prebuilts/Polybius/Polybius.apk"
  mkdir -p "$ROOT/device/gameconsole/r36s/prebuilts/PolybiusHq"
  cp -a "$SRC/PolybiusHq/PolybiusHq.apk" "$ROOT/device/gameconsole/r36s/prebuilts/PolybiusHq/PolybiusHq.apk"
  cp -a "$SRC/DoomsdayClock/DoomsdayClock.apk" "$ROOT/device/gameconsole/r36s/prebuilts/DoomsdayClock/DoomsdayClock.apk"
fi

echo "Done. APKs are gitignored; product makefiles pick them up if present."

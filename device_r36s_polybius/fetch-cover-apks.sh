#!/usr/bin/env bash
# Pull the three desk apps from upstream (not the Polybius dist branch).
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

# Brave official F-Droid repo (release / arm64-v8a when the index lists it).
# Fallback: latest release APK name from their S3 repo listing.
if [[ -n "${BRAVE_APK_URL:-}" ]]; then
  fetch_url "$BRAVE_APK_URL" "$SRC/Brave/Brave.apk"
else
  echo "Resolving Brave from official F-Droid repo index..."
  tmp="$(mktemp -d)"
  if curl -fL --retry 4 -o "$tmp/index-v2.json" \
      "https://brave-browser-apk-release.s3.brave.com/fdroid/repo/index-v2.json"; then
    python3 - "$tmp/index-v2.json" "$SRC/Brave/Brave.apk" <<'PY'
import json, sys, urllib.request
from pathlib import Path
idx = json.loads(Path(sys.argv[1]).read_text())
pkgs = idx.get("packages", {})
brave = pkgs.get("com.brave.browser") or next(iter(pkgs.values()))
versions = brave.get("versions", {})
# Prefer arm64-v8a file.
chosen = None
for ver in versions.values():
    files = ver.get("file", {})
    name = files.get("name") or ""
    if "arm64" in name or "arm64-v8a" in str(ver):
        chosen = name
        break
if not chosen:
    for ver in versions.values():
        chosen = (ver.get("file") or {}).get("name")
        if chosen:
            break
if not chosen:
    raise SystemExit("no Brave APK in index-v2")
url = "https://brave-browser-apk-release.s3.brave.com/fdroid/repo/" + chosen.lstrip("/")
print("Brave ->", url)
urllib.request.urlretrieve(url, sys.argv[2])
PY
  else
    echo "Brave index-v2 missing. Set BRAVE_APK_URL and re-run." >&2
  fi
  rm -rf "$tmp"
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

echo "Done. Cover APKs are gitignored."

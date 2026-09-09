#!/usr/bin/env bash
# Hide Polybius from the app drawer: strip CATEGORY_LAUNCHER from the
# user/HQ prebuilts and resign.
#
# Refuses the Android debug keystore unless CRYPT3X_ALLOW_DEBUG_KEYS=1.
# Production images must set CRYPT3X_KS to a release keystore.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius/prebuilts"
AAPT="${AAPT:-/opt/android-sdk/build-tools/35.0.0/aapt}"
ZIPALIGN="${ZIPALIGN:-/opt/android-sdk/build-tools/35.0.0/zipalign}"
APKSIGNER="${APKSIGNER:-/opt/android-sdk/build-tools/35.0.0/apksigner}"
KS="${CRYPT3X_KS:-}"

if [[ -z "$KS" ]]; then
  echo "Set CRYPT3X_KS to a release keystore path." >&2
  echo "Debug keys are a supply-chain hole (anyone can resign as CRYPT3X)." >&2
  echo "Override with CRYPT3X_ALLOW_DEBUG_KEYS=1 only for local bring-up." >&2
  if [[ "${CRYPT3X_ALLOW_DEBUG_KEYS:-}" != "1" ]]; then
    exit 1
  fi
  KS="/tmp/crypt3x-debug.jks"
fi

if [[ "$KS" == *debug* && "${CRYPT3X_ALLOW_DEBUG_KEYS:-}" != "1" ]]; then
  echo "Refusing debug keystore $KS (set CRYPT3X_ALLOW_DEBUG_KEYS=1 to override)." >&2
  exit 1
fi

if [[ ! -x /tmp/apktool && ! -x "$(command -v apktool || true)" ]]; then
  curl -fsSL -o /tmp/apktool.jar \
    https://github.com/iBotPeaches/Apktool/releases/download/v2.11.1/apktool_2.11.1.jar
  printf '#!/bin/sh\nexec java -jar /tmp/apktool.jar "$@"\n' > /tmp/apktool
  chmod +x /tmp/apktool
fi
APKTOOL="$(command -v apktool || echo /tmp/apktool)"

if [[ ! -f "$KS" ]]; then
  if [[ "${CRYPT3X_ALLOW_DEBUG_KEYS:-}" != "1" ]]; then
    echo "Keystore $KS does not exist." >&2
    exit 1
  fi
  keytool -genkeypair -keystore "$KS" -storepass android -keypass android \
    -alias androiddebugkey -keyalg RSA -keysize 4096 -validity 10000 \
    -dname 'CN=CRYPT3X, OU=GAME OVER, O=GAME OVER, L=BNE, ST=QLD, C=AU'
fi

strip_launcher() {
  local src="$1"
  local work="/tmp/strip-$(basename "$src" .apk)-$$"
  rm -rf "$work"
  "$APKTOOL" d -f -o "$work" "$src"
  python3 - "$work/AndroidManifest.xml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
t = p.read_text()
t2 = t.replace('<category android:name="android.intent.category.LAUNCHER"/>', '')
if t2 == t:
    raise SystemExit(f'LAUNCHER category not found in {p}')
p.write_text(t2)
print(f'stripped LAUNCHER in {p}')
PY
  "$APKTOOL" b -o "$work-unsigned.apk" "$work"
  "$ZIPALIGN" -f -p 4 "$work-unsigned.apk" "$work-aligned.apk"
  "$APKSIGNER" sign --ks "$KS" --ks-pass pass:"${CRYPT3X_KS_PASS:-android}" \
    --key-pass pass:"${CRYPT3X_KEY_PASS:-${CRYPT3X_KS_PASS:-android}}" \
    --out "$src" "$work-aligned.apk"
  echo "rewrote $src"
}

strip_launcher "$SRC/Polybius/Polybius.apk"
strip_launcher "$SRC/PolybiusHq/PolybiusHq.apk"

if [[ -d "$ROOT/device/gameconsole/r36s/prebuilts" ]]; then
  cp -a "$SRC/Polybius/Polybius.apk" \
    "$ROOT/device/gameconsole/r36s/prebuilts/Polybius/Polybius.apk"
  mkdir -p "$ROOT/device/gameconsole/r36s/prebuilts/PolybiusHq"
  cp -a "$SRC/PolybiusHq/PolybiusHq.apk" \
    "$ROOT/device/gameconsole/r36s/prebuilts/PolybiusHq/PolybiusHq.apk"
fi

echo "Done. Polybius icons are gone; vault still starts MainActivity by class name."

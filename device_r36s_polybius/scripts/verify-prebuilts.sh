#!/usr/bin/env bash
# Fail closed if a prebuilt APK's SHA-256 is not in the pin file.
# Pins live in prebuilts/SHA256SUMS (optional; skip when missing).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/device_r36s_polybius/prebuilts"
PINS="$SRC/SHA256SUMS"

if [[ ! -f "$PINS" ]]; then
  echo "No $PINS — skipping pin check. Create one after the first verified fetch."
  exit 0
fi

found=0
mismatch=0
while IFS= read -r -d '' apk; do
  found=1
  sum="$(sha256sum "$apk" | awk '{print $1}')"
  rel="${apk#"$SRC"/}"
  if grep -Eq "^${sum}[[:space:]]+(${rel}|\\*/${rel}|$(basename "$apk"))$" "$PINS" \
     || grep -Fq "$sum" "$PINS"; then
    echo "ok  $rel  $sum"
  else
    echo "FAIL $rel  $sum (not in SHA256SUMS)" >&2
    mismatch=1
  fi
done < <(find "$SRC" -name '*.apk' -print0)

if [[ "$found" -eq 0 ]]; then
  echo "No APKs under $SRC (ok — they are gitignored)."
  exit 0
fi
exit "$mismatch"

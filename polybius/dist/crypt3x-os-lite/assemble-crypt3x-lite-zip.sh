#!/usr/bin/env bash
# Rebuild CRYPT3X_OS_LITE-r36s-20260815.zip from the 80 MiB artifact parts.
set -euo pipefail
EXPECT_SHA="e79ac4225e702c3b5b5dc353198522be2141c2d6f20c8ec9df6f8cb548428f93"
EXPECT_BYTES=965251465
DIR="${1:-.}"
OUT="${2:-$DIR/CRYPT3X_OS_LITE-r36s-20260815.zip}"

parts=()
for i in $(seq -w 0 11); do
  p="$DIR/CRYPT3X_OS_LITE-r36s-20260815.zip.part$i"
  [[ -f "$p" ]] || { echo "missing $p" >&2; exit 1; }
  parts+=("$p")
done

cat "${parts[@]}" > "$OUT"
BYTES="$(stat -c '%s' "$OUT")"
if [[ "$BYTES" -ne "$EXPECT_BYTES" ]]; then
  echo "size mismatch: $BYTES (expected $EXPECT_BYTES)" >&2
  exit 2
fi
GOT="$(sha256sum "$OUT" | awk '{print $1}')"
if [[ "$GOT" != "$EXPECT_SHA" ]]; then
  echo "SHA-256 mismatch:" >&2
  echo "  expected $EXPECT_SHA" >&2
  echo "  actual   $GOT" >&2
  exit 3
fi
echo "OK $OUT ($BYTES bytes)"
echo "$GOT"

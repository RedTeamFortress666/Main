#!/usr/bin/env bash
# Mint an anonymous t3mp (temp.sh) drop. Prints the URL. Expires in 3 days.
# Usage: tool/t3mp_upload.sh FILE [FILE...]
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 FILE [FILE...]" >&2
  exit 1
fi

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "not a file: $file" >&2
    exit 1
  fi
  url=$(curl -sS -F "file=@${file}" https://temp.sh/upload | tr -d '\r')
  url="${url%%$'\n'*}"
  if [[ "$url" != https://temp.sh/* ]]; then
    echo "t3mp upload failed for $file: $url" >&2
    exit 1
  fi
  printf '%s\t%s\n' "$(basename "$file")" "$url"
done

#!/usr/bin/env bash
# Clone Motorola edge 30 neo (miami) LineageOS 23.2 trees into this workspace
# at the paths breakfast/repo expect. Nested checkouts are gitignored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRANCH="${LINEAGE_BRANCH:-lineage-23.2}"
FORK_ORG="${FORK_ORG:-RedTeamFortress666}"

clone_one() {
  local path="$1" upstream_url="$2" fork_repo="$3"
  local dest="$ROOT/$path"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$dest/.git" ]]; then
    echo "exists: $path"
  else
    echo "clone:  $path"
    git clone --depth 1 --single-branch -b "$BRANCH" "$upstream_url" "$dest"
  fi
  git -C "$dest" remote remove upstream 2>/dev/null || true
  if git -C "$dest" remote get-url origin >/dev/null 2>&1; then
    local origin_url
    origin_url="$(git -C "$dest" remote get-url origin)"
    if [[ "$origin_url" == *"${FORK_ORG}/"* ]]; then
      :
    else
      git -C "$dest" remote rename origin upstream 2>/dev/null || \
        git -C "$dest" remote set-url upstream "$upstream_url"
    fi
  fi
  if ! git -C "$dest" remote get-url upstream >/dev/null 2>&1; then
    git -C "$dest" remote add upstream "$upstream_url"
  fi
  git -C "$dest" remote set-url upstream "$upstream_url"
  if git -C "$dest" remote get-url origin >/dev/null 2>&1; then
    git -C "$dest" remote set-url origin "https://github.com/${FORK_ORG}/${fork_repo}.git"
  else
    git -C "$dest" remote add origin "https://github.com/${FORK_ORG}/${fork_repo}.git"
  fi
  echo "  HEAD=$(git -C "$dest" rev-parse --short HEAD) upstream=$(git -C "$dest" remote get-url upstream)"
  echo "  origin=$(git -C "$dest" remote get-url origin)  (push after GitHub fork exists)"
}

cd "$ROOT"
mkdir -p device/motorola kernel/motorola hardware vendor/motorola .repo/local_manifests

cp -f "$ROOT/lineage-miami/local_manifests/miami.xml" \
  "$ROOT/.repo/local_manifests/miami.xml"

clone_one device/motorola/miami \
  https://github.com/LineageOS/android_device_motorola_miami.git \
  android_device_motorola_miami

clone_one device/motorola/sm6375-common \
  https://github.com/LineageOS/android_device_motorola_sm6375-common.git \
  android_device_motorola_sm6375-common

clone_one hardware/motorola \
  https://github.com/LineageOS/android_hardware_motorola.git \
  android_hardware_motorola

clone_one kernel/motorola/sm6375 \
  https://github.com/LineageOS/android_kernel_motorola_sm6375.git \
  android_kernel_motorola_sm6375

clone_one vendor/motorola/miami \
  https://github.com/TheMuppets/proprietary_vendor_motorola_miami.git \
  proprietary_vendor_motorola_miami

clone_one vendor/motorola/sm6375-common \
  https://github.com/TheMuppets/proprietary_vendor_motorola_sm6375-common.git \
  proprietary_vendor_motorola_sm6375-common

echo "done. trees are gitignored; see MIAMI.md"

#!/usr/bin/env bash
# Create GitHub forks of the miami LineageOS / TheMuppets trees.
# Requires a GitHub token with repo fork permission (this Cloud Agent token
# is read-only and cannot run these commands successfully).
set -euo pipefail

FORK_ORG="${FORK_ORG:-RedTeamFortress666}"

repos=(
  LineageOS/android_device_motorola_miami
  LineageOS/android_device_motorola_sm6375-common
  LineageOS/android_kernel_motorola_sm6375
  LineageOS/android_hardware_motorola
  TheMuppets/proprietary_vendor_motorola_miami
  TheMuppets/proprietary_vendor_motorola_sm6375-common
)

for repo in "${repos[@]}"; do
  name="${repo#*/}"
  echo "fork $repo -> ${FORK_ORG}/${name}"
  gh repo fork "$repo" --clone=false --default-branch-only \
    --org "$FORK_ORG" 2>/dev/null || \
  gh repo fork "$repo" --clone=false --default-branch-only
done

echo "After forks exist, retarget local remotes:"
echo "  ./lineage-miami/clone-trees.sh"
echo "And use lineage-miami/local_manifests/miami-fork.xml in the Android tree."

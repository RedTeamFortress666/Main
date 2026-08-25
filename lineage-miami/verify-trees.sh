#!/usr/bin/env bash
# Sanity-check miami trees after clone-trees.sh. Does not build LineageOS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

need() {
  if [[ ! -e "$ROOT/$1" ]]; then
    echo "MISSING $1"
    fail=1
  else
    echo "ok      $1"
  fi
}

need device/motorola/miami/AndroidProducts.mk
need device/motorola/miami/lineage_miami.mk
need device/motorola/miami/BoardConfig.mk
need device/motorola/miami/extract-files.py
need device/motorola/miami/lineage.dependencies
need device/motorola/sm6375-common/BoardConfigCommon.mk
need device/motorola/sm6375-common/common.mk
need hardware/motorola
need kernel/motorola/sm6375/arch/arm64/configs/vendor/holi-qgki_defconfig
need kernel/motorola/sm6375/arch/arm64/configs/vendor/ext_config/lineage_moto-holi.config
need kernel/motorola/sm6375/arch/arm64/configs/vendor/ext_config/moto-holi-miami.config
need kernel/motorola/sm6375/arch/arm64/boot/dts/vendor/qcom/blair-moto-miami-base.dts
need vendor/motorola/miami/miami-vendor.mk
need vendor/motorola/miami/BoardConfigVendor.mk
need vendor/motorola/sm6375-common/sm6375-common-vendor.mk
need vendor/motorola/sm6375-common/BoardConfigVendor.mk
need .repo/local_manifests/miami.xml

if grep -q 'PRODUCT_NAME := lineage_miami' "$ROOT/device/motorola/miami/lineage_miami.mk"; then
  echo "ok      lunch target lineage_miami"
else
  echo "MISSING lunch target lineage_miami"
  fail=1
fi

if grep -q 'android_device_motorola_miami' "$ROOT/.repo/local_manifests/miami.xml"; then
  echo "ok      local_manifest miami.xml"
else
  echo "MISSING local_manifest contents"
  fail=1
fi

echo "--- remotes ---"
for d in device/motorola/miami device/motorola/sm6375-common hardware/motorola \
         kernel/motorola/sm6375 vendor/motorola/miami vendor/motorola/sm6375-common; do
  echo "$d  HEAD=$(git -C "$ROOT/$d" rev-parse --short HEAD)"
  echo "  upstream=$(git -C "$ROOT/$d" remote get-url upstream 2>/dev/null || echo NONE)"
  echo "  origin=$(git -C "$ROOT/$d" remote get-url origin 2>/dev/null || echo NONE)"
done

exit "$fail"

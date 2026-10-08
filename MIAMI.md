# Motorola edge 30 neo (miami) — LineageOS 23.2 fork

Official LineageOS device: [wiki.lineageos.org/devices/miami](https://wiki.lineageos.org/devices/miami/).
Codename **miami**, models **XT2245-1**, Snapdragon 695 (SM6375 / `holi`), kernel 5.4.
Current official branch: **lineage-23.2** (Android 16). Also published: 22.2, 23.0. Maintainer: marcost2.

This workspace has **begun the fork**: device, common, kernel, Motorola HAL, and TheMuppets vendor trees are cloned at the Android paths `breakfast miami` uses. The full LineageOS source (~100GB+ sync, ~400GB to build) is **not** downloaded. Ask before running `repo sync`.

GitHub forks under `RedTeamFortress666/` are **not created yet**. The Cloud Agent `gh` token cannot create GitHub repos. Local remotes are already split: `upstream` = LineageOS/TheMuppets, `origin` = intended fork URLs.

## What is already cloned

| Path | Upstream | Branch | Approx. size |
| --- | --- | --- | --- |
| `device/motorola/miami` | [android_device_motorola_miami](https://github.com/LineageOS/android_device_motorola_miami) | `lineage-23.2` | 1.1M |
| `device/motorola/sm6375-common` | [android_device_motorola_sm6375-common](https://github.com/LineageOS/android_device_motorola_sm6375-common) | `lineage-23.2` | 4.3M |
| `hardware/motorola` | [android_hardware_motorola](https://github.com/LineageOS/android_hardware_motorola) | `lineage-23.2` | 1.7M |
| `kernel/motorola/sm6375` | [android_kernel_motorola_sm6375](https://github.com/LineageOS/android_kernel_motorola_sm6375) | `lineage-23.2` | 1.6G (shallow) |
| `vendor/motorola/miami` | [proprietary_vendor_motorola_miami](https://github.com/TheMuppets/proprietary_vendor_motorola_miami) | `lineage-23.2` | 344M |
| `vendor/motorola/sm6375-common` | [proprietary_vendor_motorola_sm6375-common](https://github.com/TheMuppets/proprietary_vendor_motorola_sm6375-common) | `lineage-23.2` | 390M |

These directories are gitignored. Each is its own git checkout. Pinned SHAs: `lineage-miami/PINNED_REVS.txt`.

Re-clone / retarget remotes:

```bash
./lineage-miami/clone-trees.sh
./lineage-miami/verify-trees.sh
```

## Fork process (started locally, GitHub next)

1. **Local trees** — done. `clone-trees.sh` sets:
   - `upstream` → LineageOS or TheMuppets
   - `origin` → `https://github.com/RedTeamFortress666/<same-repo-name>.git`
2. **Create GitHub forks** (needs a token that can fork; not this agent):

   ```bash
   ./lineage-miami/create-github-forks.sh
   ```

   Repos to fork:

   - `LineageOS/android_device_motorola_miami`
   - `LineageOS/android_device_motorola_sm6375-common`
   - `LineageOS/android_kernel_motorola_sm6375`
   - `LineageOS/android_hardware_motorola`
   - `TheMuppets/proprietary_vendor_motorola_miami`
   - `TheMuppets/proprietary_vendor_motorola_sm6375-common`

3. **Push the lineage-23.2 branch** to each fork (`git push -u origin lineage-23.2`).
4. **Point `repo` at the forks** — copy `lineage-miami/local_manifests/miami-fork.xml` to `.repo/local_manifests/miami.xml` in the Android tree.

Until step 2 exists, keep using `lineage-miami/local_manifests/miami.xml` (upstream).

## Dependency chain (`lineage.dependencies`)

```
device/motorola/miami
  └── device/motorola/sm6375-common
        ├── kernel/motorola/sm6375
        └── hardware/motorola
vendor/motorola/miami          # TheMuppets (or extract-files.py from a device/zip)
vendor/motorola/sm6375-common
```

Lunch / brunch target: `lineage_miami` (`device/motorola/miami/AndroidProducts.mk`).
Product model string: `moto edge 30 neo`. A/B + virtual A/B with vendor ramdisk. Platform `holi`.

## Important files

```
device/motorola/miami/
  AndroidProducts.mk          # PRODUCT_MAKEFILES := lineage_miami.mk
  lineage_miami.mk            # PRODUCT_NAME := lineage_miami
  BoardConfig.mk              # TARGET_KERNEL_CONFIG += vendor/ext_config/moto-holi-miami.config
  device.mk                   # overlays, audio, fingerprint, NFC, inherits vendor
  extract-files.py            # blob extract (needs Lineage extract-utils in the full tree)
  lineage.dependencies        # pulls sm6375-common
  fingerprint/                # android.hardware.biometrics.fingerprint@2.3-service.miami
  resource-overlay/           # Frameworks / SystemUI / Settings / Wifi / LineageSystemUI
  audio/                      # mixer_paths, policy, platform_info

device/motorola/sm6375-common/
  BoardConfigCommon.mk        # TARGET_KERNEL_SOURCE := kernel/motorola/sm6375
                              # TARGET_KERNEL_CONFIG := vendor/holi-qgki_defconfig
                              #                       vendor/ext_config/lineage_moto-holi.config
  common.mk                   # CAF common, virtual A/B, vendor inherit
  lineage.dependencies        # kernel + hardware/motorola

kernel/motorola/sm6375/
  arch/arm64/configs/vendor/holi-qgki_defconfig
  arch/arm64/configs/vendor/ext_config/lineage_moto-holi.config
  arch/arm64/configs/vendor/ext_config/moto-holi-miami.config
  arch/arm64/boot/dts/vendor/qcom/blair-moto-miami-base.dts
```

`hardware/qcom-caf/*` and the rest of AOSP/Lineage come from `repo init` of LineageOS/android, not from these six trees.

## Full LineageOS 23.2 environment (do not run yet)

Need ~400GB free disk, 64GB RAM (Lineage wiki for lineage-21+), and a fast network. First sync is tens of GB.

Official wiki: [Build for miami](https://wiki.lineageos.org/devices/miami/build/).

```bash
mkdir -p ~/bin ~/android/lineage
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --no-clone-bundle
mkdir -p .repo/local_manifests
cp /path/to/this/repo/lineage-miami/local_manifests/miami.xml .repo/local_manifests/miami.xml
repo sync

source build/envsetup.sh
breakfast miami
brunch miami
```

Outputs of interest in `$OUT`:

- `boot.img`
- `lineage-23.2-YYYYMMDD-UNOFFICIAL-miami.zip`

Proprietary blobs: this clone already has TheMuppets dumps. On a device running matching Lineage, you can also run `device/motorola/miami/extract-files.py`.

Do **not** `repo init` inside this React/Flutter workspace unless you intend to sync ~100GB here.

## Next steps

1. Create the six GitHub forks (`create-github-forks.sh`) and push `lineage-23.2`.
2. Switch the Android tree to `miami-fork.xml`.
3. Confirm you want the full `repo sync` + `brunch miami` (400GB-class machine).
4. Official prebuilt images (if you only need to run Lineage, not fork it): [LineageOS miami downloads](https://download.lineageos.org/devices/miami/builds).

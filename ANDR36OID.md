# AndR36oid / LineageOS 18.1 for Game Console R36S (RK3326)

Device, common, kernel, and Rockchip HAL trees are cloned in this workspace at the
paths the official AndR36oid `local_manifests` uses. The full LineageOS source
(~50GB download, ~200GB to build) is **not** synced. Ask before running `repo sync`.

Upstream org: https://github.com/andr36oid

## What is already cloned

| Path | Upstream | Branch | Approx. size |
| --- | --- | --- | --- |
| `device/gameconsole/r36s` | [android_device_gameconsole_r36s](https://github.com/andr36oid/android_device_gameconsole_r36s) | `lineage-18.1` | 47M |
| `device/gameconsole/common` | [android_device_gameconsole_common](https://github.com/andr36oid/android_device_gameconsole_common) | `lineage-18.1` | 212M |
| `kernel/gameconsole/r36s` | [android_kernel_gameconsole_r36s](https://github.com/andr36oid/android_kernel_gameconsole_r36s) | `lineage-18.1` | 1.6G (shallow + submodules) |
| `hardware/rockchip` | [android_hardware_rockchip](https://github.com/andr36oid/android_hardware_rockchip) | `lineage-18.1` | 21M |
| `.repo/local_manifests` | [local_manifests](https://github.com/andr36oid/local_manifests) | `main` | tiny |
| `docker_build` | [docker_build](https://github.com/andr36oid/docker_build) | `main` | tiny |

These directories are gitignored in this repo. Each is its own git checkout.

Re-clone later (shallow, matching the official manifest):

```bash
mkdir -p device/gameconsole kernel/gameconsole hardware .repo

git clone --depth 1 -b lineage-18.1 \
  https://github.com/andr36oid/android_device_gameconsole_r36s.git \
  device/gameconsole/r36s

git clone --depth 1 -b lineage-18.1 \
  https://github.com/andr36oid/android_device_gameconsole_common.git \
  device/gameconsole/common

git clone --depth 1 --recurse-submodules -b lineage-18.1 \
  https://github.com/andr36oid/android_kernel_gameconsole_r36s.git \
  kernel/gameconsole/r36s

git clone --depth 1 -b lineage-18.1 \
  https://github.com/andr36oid/android_hardware_rockchip.git \
  hardware/rockchip

git clone --depth 1 -b main \
  https://github.com/andr36oid/local_manifests.git \
  .repo/local_manifests

git clone --depth 1 -b main \
  https://github.com/andr36oid/docker_build.git \
  docker_build
```

## Other AndR36oid repos (not cloned)

There is **no separate `vendor/` proprietary dump**. Wi-Fi/BT firmware and most
board support live in `device/gameconsole/common` (`firmware/`, HALs, overlays).

### Required for a full image build (pulled by `repo sync`)

Use AndR36oid's manifest, not stock LineageOS. Their `android` manifest retargets
these projects to AndR36oid forks:

- [andr36oid/android](https://github.com/andr36oid/android) — repo manifest (`lineage-18.1`)
- [andr36oid/android_build](https://github.com/andr36oid/android_build), [android_build_soong](https://github.com/andr36oid/android_build_soong)
- [android_art](https://github.com/andr36oid/android_art), [android_bionic](https://github.com/andr36oid/android_bionic)
- [android_frameworks_av](https://github.com/andr36oid/android_frameworks_av), [android_frameworks_base](https://github.com/andr36oid/android_frameworks_base), [android_frameworks_native](https://github.com/andr36oid/android_frameworks_native)
- [android_frameworks_opt_net_wifi](https://github.com/andr36oid/android_frameworks_opt_net_wifi)
- [android_hardware_interfaces](https://github.com/andr36oid/android_hardware_interfaces), [android_hardware_libhardware](https://github.com/andr36oid/android_hardware_libhardware)
- [android_system_core](https://github.com/andr36oid/android_system_core), [android_system_hardware_interfaces](https://github.com/andr36oid/android_system_hardware_interfaces), [android_system_memory_ion](https://github.com/andr36oid/android_system_memory_ion)
- [android_packages_apps_Settings](https://github.com/andr36oid/android_packages_apps_Settings)
- [android_external_compiler-rt](https://github.com/andr36oid/android_external_compiler-rt), [android_external_libdrm](https://github.com/andr36oid/android_external_libdrm)
- [android_lineage-sdk](https://github.com/andr36oid/android_lineage-sdk)
- [gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu](https://github.com/andr36oid/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu) — kernel cross compiler (Docker installs it under `/opt/toolchains/...`)

### Optional / sibling devices

- [android_device_gameconsole_r50s](https://github.com/andr36oid/android_device_gameconsole_r50s)
- [android_device_gameconsole_r46h](https://github.com/andr36oid/android_device_gameconsole_r46h)
- [android_device_gameconsole_common_old](https://github.com/andr36oid/android_device_gameconsole_common_old) — superseded
- [u-boot](https://github.com/andr36oid/u-boot) — bootloader source; prebuilt `idbloader.img` / `uboot.img` / `trust.img` are already in `device/gameconsole/r36s/bootloader/`
- [releases](https://github.com/andr36oid/releases) — flashable images, not source
- `local_manifests` branch `analog-stick-mouse` — alternate device config

## Full LineageOS 18.1 environment (do not run yet)

Need ~200GB free disk, 16GB+ RAM, and a fast network. First sync is ~50GB.

### Option A — official Docker builder (recommended)

```bash
cd docker_build
docker compose up -d
docker compose logs -f
```

That image runs `repo init` against **AndR36oid's** manifest, syncs, lunches
`lineage_r36s-userdebug`, builds `bootimage` + `systemimage`, then runs
`device/gameconsole/r36s/mkimg.sh`. Output lands in `docker_build/results/`.

### Option B — host `repo` init + sync

```bash
# Ubuntu packages (also listed in docker_build/Dockerfile)
sudo apt-get update
sudo apt-get install -y repo git git-lfs bc bison build-essential ccache curl flex \
  g++-multilib gcc-multilib gnupg gperf imagemagick protobuf-compiler python3-protobuf \
  lib32readline-dev lib32z1-dev libdw-dev libelf-dev lz4 libsdl1.2-dev libssl-dev \
  libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
  zlib1g-dev libncurses5-dev python-is-python3 mtools kpartx wget parted dosfstools

# Use a dedicated Android tree, not this React/Flutter workspace root, if possible:
mkdir -p ~/android/andr36oid && cd ~/android/andr36oid

repo init -u https://github.com/andr36oid/android.git -b lineage-18.1 --git-lfs
git clone -b main https://github.com/andr36oid/local_manifests.git .repo/local_manifests
repo sync -j4

# Kernel toolchain expected by BoardConfig.mk
sudo mkdir -p /opt/toolchains
sudo git clone --depth=1 \
  https://github.com/andr36oid/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu \
  /opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
```

Do **not** `repo init` against `https://github.com/LineageOS/android.git` if you
want a working AndR36oid image. Their patched `frameworks/*`, `bionic`, `art`,
and Rockchip HALs come from the AndR36oid manifest.

If you init inside this workspace, `repo sync` will refresh the four trees
already cloned here via `.repo/local_manifests/local_manifests.xml`.

## Important files in the R36S device tree

```
device/gameconsole/r36s/
  AndroidProducts.mk     # lunch targets: lineage_r36s-{user,userdebug,eng}
  lineage_r36s.mk        # product: inherits common + r36s device.mk
  BoardConfig.mk         # TARGET_KERNEL_CONFIG := lineageos_r36s_defconfig
  device.mk              # R36S overlays / display orientation
  mkimg.sh               # packs GPT SD image (needs root + built out/)
  mkimg_plus.sh          # R36S Plus variant
  mkota.sh               # recovery OTA zip
  Image-recovery         # prebuilt recovery kernel
  BOOT/                  # boot.ini, panel DTBs, logos
  bootloader/            # idbloader.img, uboot.img, trust.img
  overlay/               # framework overlays
  ramdisk/               # userdata resize helpers

device/gameconsole/common/
  BoardConfig.mk         # RK3326 SoC, kernel source path, partitions
  device.mk              # packages, firmware, wifi, audio, mali
  firmware/              # Realtek / MediaTek / Ralink blobs (acts as vendor)
  patches/               # apply-patches.sh for AndR36oid framework forks
  sepolicy/, wifi/, mali/, audio/, bluetooth/

kernel/gameconsole/r36s/
  arch/arm64/configs/lineageos_r36s_defconfig
  arch/arm64/boot/dts/rockchip/rk3326-r36s-android-panel{0-6}.dts
```

`lineage_r36s.mk` includes `device/gameconsole/common/BoardConfig.mk` and
`device/gameconsole/common/device.mk`. The R36S tree is a thin product overlay
on that common RK3326 board.

## Specialized product: CRYPT3X OS (`lineage_r36s_crypt3x`)

A second lunch target lives in `device_r36s_polybius/`. It keeps stock
AndR36oid hardware bring-up and adds Polybius + vault + mesh/privacy policy.
The visible fork name is **CRYPT3X OS**, credited to GÅMÊ ØVĒR on the boot card.

```bash
./device_r36s_polybius/apply.sh
# then, after a full repo sync:
source build/envsetup.sh
lunch lineage_r36s_crypt3x-userdebug
```

See `device_r36s_polybius/README.md` for APK drop-in paths and what is in/out
of the image. Do not run `repo sync` until you ask for the full tree.

## Next steps to actually build an image

1. Confirm you want the full ~50GB `repo sync` (and ~200GB build disk).
2. Prefer `docker_build` on a machine with Docker, 16GB+ RAM, and 200GB free.
3. After sync:

   ```bash
   source build/envsetup.sh
   lunch lineage_r36s-userdebug
   mka -j$(nproc) bootimage systemimage
   cd device/gameconsole/r36s
   sudo ./mkimg.sh
   ```

4. Flash the resulting `lineage-18.1-YYYYMMDD-HHMM-r36s-android.img` (zipped by
   the Docker flow) to a microSD. Panel DTBs live under `BOOT/Panels/`; default
   in `mkimg.sh` is Panel 4.
5. Prebuilt releases (if you only need to run Android, not build it):
   https://github.com/andr36oid/releases

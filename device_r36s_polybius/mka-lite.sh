#!/usr/bin/env bash
# Host MKA for CRYPT3X OS lite (lineage_r36s_crypt3x_lite-userdebug).
# Uses a dedicated AndR36oid tree so the React/Flutter workspace stays clean.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-/opt/android/andr36oid}"
BUILD_TARGET="${BUILD_TARGET:-lineage_r36s_crypt3x_lite-userdebug}"
REPO_SYNC_JOBS="${REPO_SYNC_JOBS:-4}"
BUILD_JOBS="${BUILD_JOBS:-2}"
LOG="${MKA_LITE_LOG:-/opt/android/mka-lite.log}"
SWAPFILE="${SWAPFILE:-/opt/android/swapfile}"
SWAP_GIB="${SWAP_GIB:-32}"
TOOLCHAIN="/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}"

export ANDROID_ROOT
export USE_CCACHE="${USE_CCACHE:-1}"
export CCACHE_DIR="${CCACHE_DIR:-/opt/android/ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-15G}"
export ANDROID_JACK_VM_ARGS="${ANDROID_JACK_VM_ARGS:--Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G}"
export PATH="${JAVA_HOME}/bin:/usr/bin:${PATH}"

sudo mkdir -p /opt/android /opt/android/ccache "$(dirname "$LOG")"
sudo chown -R "$(id -u):$(id -g)" /opt/android
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "========================================"
echo "CRYPT3X OS lite MKA"
echo "ANDROID_ROOT=$ANDROID_ROOT"
echo "BUILD_TARGET=$BUILD_TARGET"
echo "BUILD_JOBS=$BUILD_JOBS REPO_SYNC_JOBS=$REPO_SYNC_JOBS"
echo "started $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "========================================"

need_pkg() {
  dpkg -s "$1" >/dev/null 2>&1
}

install_host_deps() {
  local pkgs=(
    repo git git-lfs bc bison build-essential ccache curl flex
    g++-multilib gcc-multilib gnupg gperf imagemagick protobuf-compiler
    python3-protobuf lib32readline-dev lib32z1-dev libdw-dev libelf-dev
    lz4 libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync
    schedtool squashfs-tools xsltproc zip zlib1g-dev libncurses5-dev
    python-is-python3 mtools kpartx wget parted dosfstools
    openjdk-11-jdk
  )
  local missing=()
  local p
  for p in "${pkgs[@]}"; do
    need_pkg "$p" || missing+=("$p")
  done
  if ((${#missing[@]})); then
    echo "Installing host packages: ${missing[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
  else
    echo "Host build packages already installed."
  fi
  if ! need_pkg libncurses5; then
    echo "Installing libncurses5 from Ubuntu 22.04 (not in 24.04)"
    wget -q -O /tmp/libtinfo5.deb https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb
    wget -q -O /tmp/libncurses5.deb https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb
    sudo dpkg -i /tmp/libtinfo5.deb /tmp/libncurses5.deb
  fi
  git lfs install --skip-repo >/dev/null 2>&1 || true
}

ensure_swap() {
  if swapon --show | grep -q .; then
    echo "Swap already on:"
    swapon --show
    return
  fi
  echo "Creating ${SWAP_GIB}GiB swap at $SWAPFILE"
  sudo mkdir -p "$(dirname "$SWAPFILE")"
  if [[ ! -f "$SWAPFILE" ]]; then
    if ! sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SWAP_GIB * 1024)) status=progress; then
      echo "WARN: could not allocate swap file; continuing without swap"
      return
    fi
  fi
  sudo chmod 600 "$SWAPFILE"
  sudo mkswap "$SWAPFILE"
  # OverlayFS rejects swapon on a file; bind it to a loop device first.
  if ! sudo swapon "$SWAPFILE" 2>/dev/null; then
    local loop
    loop="$(sudo losetup --find --show --direct-io=on "$SWAPFILE" 2>/dev/null \
      || sudo losetup --find --show "$SWAPFILE")"
    sudo mkswap "$loop"
    if ! sudo swapon "$loop"; then
      echo "WARN: swapon failed on $loop; continuing without swap"
      sudo losetup -d "$loop" || true
      return
    fi
    echo "Swap on loop $loop"
  fi
  swapon --show
}

ensure_toolchain() {
  if [[ -x "$TOOLCHAIN/bin/aarch64-linux-gnu-gcc" ]]; then
    echo "Linaro toolchain present."
    return
  fi
  echo "Cloning Linaro 6.3.1 kernel toolchain..."
  sudo mkdir -p /opt/toolchains
  sudo git clone --depth=1 \
    https://github.com/andr36oid/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu \
    "$TOOLCHAIN"
}

ensure_java11() {
  if [[ ! -x "$JAVA_HOME/bin/java" ]]; then
    echo "OpenJDK 11 missing at $JAVA_HOME" >&2
    exit 1
  fi
  echo "JAVA: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"
}

seed_existing_trees() {
  mkdir -p "$ANDROID_ROOT"
  if [[ -d "$ROOT/device/gameconsole/r36s/.git" && ! -d "$ANDROID_ROOT/device/gameconsole/r36s/.git" ]]; then
    echo "Seeding device/kernel/hardware from workspace clones..."
    mkdir -p "$ANDROID_ROOT/device" "$ANDROID_ROOT/kernel" "$ANDROID_ROOT/hardware"
    rsync -a "$ROOT/device/" "$ANDROID_ROOT/device/"
    rsync -a "$ROOT/kernel/" "$ANDROID_ROOT/kernel/"
    rsync -a "$ROOT/hardware/" "$ANDROID_ROOT/hardware/"
  fi
}

ensure_repo() {
  cd "$ANDROID_ROOT"
  if [[ ! -d .repo/manifests ]]; then
    echo "repo init andr36oid/android lineage-18.1"
    repo init -u https://github.com/andr36oid/android.git -b lineage-18.1 --git-lfs
  else
    echo "Repo already initialized."
  fi
  if [[ ! -f .repo/local_manifests/local_manifests.xml ]]; then
    rm -rf .repo/local_manifests
    if [[ -f "$ROOT/.repo/local_manifests/local_manifests.xml" ]]; then
      mkdir -p .repo/local_manifests
      cp -a "$ROOT/.repo/local_manifests/." .repo/local_manifests/
    else
      git clone -b main https://github.com/andr36oid/local_manifests.git .repo/local_manifests
    fi
  fi
}

sync_tree() {
  cd "$ANDROID_ROOT"
  echo "repo sync -j${REPO_SYNC_JOBS} (this is the long download)"
  repo sync -j"${REPO_SYNC_JOBS}" --force-sync --no-clone-bundle --current-branch --no-tags
  echo "repo sync finished $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

apply_overlay() {
  echo "Applying CRYPT3X overlay into $ANDROID_ROOT"
  ANDROID_ROOT="$ANDROID_ROOT" "$ROOT/device_r36s_polybius/apply.sh"
}

mka_images() {
  cd "$ANDROID_ROOT"
  set +u
  # shellcheck disable=SC1091
  source build/envsetup.sh
  lunch "$BUILD_TARGET"
  set -u
  echo "mka -j${BUILD_JOBS} bootimage systemimage started $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mka -j"${BUILD_JOBS}" bootimage systemimage
  echo "mka finished $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

pack_sd() {
  cd "$ANDROID_ROOT/device/gameconsole/r36s"
  if [[ ! -x ./mkimg_lite.sh ]]; then
    echo "mkimg_lite.sh missing after apply" >&2
    exit 1
  fi
  echo "Packing 8GiB lite SD image"
  sudo env ANDROID_PRODUCT_OUT="${ANDROID_PRODUCT_OUT:-$ANDROID_ROOT/out/target/product/r36s}" \
    ./mkimg_lite.sh
  ls -lh lineage-18.1-*-r36s-crypt3x-lite.img* 2>/dev/null || true
}

install_host_deps
ensure_java11
ensure_swap
ensure_toolchain
mkdir -p "$CCACHE_DIR"
seed_existing_trees
ensure_repo
sync_tree
apply_overlay
mka_images
pack_sd

echo "========================================"
echo "CRYPT3X OS lite MKA complete $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Log: $LOG"
echo "========================================"

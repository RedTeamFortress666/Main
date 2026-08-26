# PØLYBĪUS — BETA build guide

Version: `1.1.0+4` (see `pubspec.yaml`).

Flutter app (Dart). One codebase targets web, Linux desktop, Android and iOS.
This document lists the exact commands, prerequisites and known blockers per
target so a BETA can be compiled and side-loaded.

## Prerequisites (all targets)

- Flutter stable (tested on 3.44.x). `flutter pub get` in `polybius/`.
- `flutter doctor` should be clean for whichever target you build.

## Web (works today)

```bash
flutter build web --release
# output: build/web  (static site; serve with any static file server)
```

Good for quick BETA testing in a browser and for the "web export" path.

## Linux desktop / R36 Max/Pro (ARM Linux handheld)

Prerequisites on the build machine:

```bash
sudo apt-get install -y ninja-build cmake clang pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-14-dev
flutter build linux --release
# output: build/linux/<arch>/release/bundle/
```

**R36 Max/Pro caveat (important):** the R36 devices are **ARM (aarch64)**
Linux handhelds. `flutter build linux` produces a binary for the *host*
architecture, so an x86-64 build machine yields an x86-64 bundle that will
**not** run on the ARM handheld. To ship for R36 you must either:

1. Build on the device itself (or an aarch64 Linux box) with the Flutter Linux
   toolchain installed, or
2. Cross-compile for aarch64 (requires an aarch64 sysroot; see
   `flutter build linux --target-platform linux-arm64`, which still needs an
   aarch64 GTK sysroot available to CMake), or
3. Let CI do it: the `linux-arm64` job in `.github/workflows/release.yml` runs
   on a native `ubuntu-24.04-arm` runner and uploads `polybius-linux-arm64`.

### Cross-compiling aarch64 from an x86-64 host (how the committed bundle was made)

Recent Flutter stable gates the x64→arm64 desktop cross-build behind an
explicit "not currently supported" check, but the underlying CMake wiring
(`clang --target=aarch64-linux-gnu` + `--target-sysroot` +
`FLUTTER_TARGET_PLATFORM_SYSROOT`) still works. The committed
`dist/polybius-1.0.0-beta.1-linux-arm64.tar.gz` was produced like this:

```bash
# 1. Host tools (all amd64 — no arm64 execution needed to install these):
sudo apt-get install -y clang ninja-build cmake pkg-config \
  binutils-aarch64-linux-gnu qemu-user-static

# 2. Build an arm64 sysroot by DOWNLOADING (not installing) arm64 .debs and
#    extracting them with dpkg-deb -x — this runs no maintainer scripts, so it
#    works on an x86-64 box with no arm64/binfmt support:
sudo apt-get install -y --download-only -o Dir::Cache::archives=/opt/arm64-debs \
  libgtk-3-dev:arm64 libglib2.0-dev:arm64 liblzma-dev:arm64 libc6-dev:arm64 \
  libstdc++-14-dev:arm64 libgstreamer1.0-dev:arm64 \
  libgstreamer-plugins-base1.0-dev:arm64 libsecret-1-dev:arm64 libjsoncpp-dev:arm64
for d in /opt/arm64-debs/*_arm64.deb /opt/arm64-debs/*_all.deb; do
  sudo dpkg-deb -x "$d" /opt/arm64-sysroot; done
# usr-merge so libc linker scripts (/lib/aarch64-linux-gnu/...) resolve:
sudo ln -sfn usr/lib /opt/arm64-sysroot/lib
# arch-independent bits that resolve to the host arch (X protocol headers/.pc,
# shared-mime-info.pc) are safe to copy from the host:
sudo cp -n /usr/share/pkgconfig/*.pc /opt/arm64-sysroot/usr/share/pkgconfig/
sudo cp -rn /usr/include/X11/. /opt/arm64-sysroot/usr/include/X11/

# 3. Provide the arm64 engine artifacts Flutter won't auto-fetch for a cross
#    target (download from the release engine bundle for your engine.version),
#    and wrap the arm64 gen_snapshot to run under qemu so AOT works on x64:
#      bin/cache/artifacts/engine/linux-arm64-release/{libflutter_linux_gtk.so,flutter_linux/,gen_snapshot}
#      bin/cache/artifacts/engine/linux-arm64/icudtl.dat   # arch-independent, copy from linux-x64
#    gen_snapshot wrapper:
#      #!/bin/bash
#      exec qemu-aarch64-static -L /opt/arm64-sysroot "$(dirname "$0")/gen_snapshot.real" "$@"

# 4. Build (the guard in flutter_tools/lib/src/commands/build_linux.dart that
#    throwToolExits on x64->arm64 must be removed/commented in your local SDK):
export PKG_CONFIG_SYSROOT_DIR=/opt/arm64-sysroot
export PKG_CONFIG_LIBDIR=/opt/arm64-sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:/opt/arm64-sysroot/usr/share/pkgconfig
export CFLAGS=--sysroot=/opt/arm64-sysroot CXXFLAGS=--sysroot=/opt/arm64-sysroot LDFLAGS=--sysroot=/opt/arm64-sysroot
flutter build linux --release --target-platform=linux-arm64 --target-sysroot=/opt/arm64-sysroot
# verify: file build/linux/arm64/release/bundle/polybius  -> "ELF 64-bit ... ARM aarch64"
```

The native CI path (option 3) needs none of this and is the recommended
producer; the cross recipe exists so a committed bundle can be made without an
arm64 machine. Either way the result is **unverified on the physical R36
hardware** (low-end RK3326 GPU/GTK support varies) — treat it as a BETA.

**Controls on R36:** the game supports **touch drag** (move toward finger),
**WASD/arrow keys**, and **hardware gamepad** analog stick / d-pad via the
`gamepads` plugin. The gamepad mapping is **best-effort and untested on the R36
hardware** — event key names and axis ranges vary by device/driver, so expect
to tune `_onGamepadEvent` in `lib/features/game/polybius_game.dart` (deadzone,
axis key matching) per device. On web the gamepad plugin is inactive (no web
backend); touch/keyboard still work.

## Android

Prerequisites: Android SDK (via Android Studio or command-line tools), a JDK
(17+), and a **release keystore**.

```bash
flutter build apk --release        # single APK
flutter build appbundle --release  # Play/AAB
# output: build/app/outputs/
```

Release signing is now wired: if `android/key.properties` exists it is used to
sign release builds; otherwise the build falls back to debug signing so
`flutter run --release` still works for BETA. To ship a distributable build:

```bash
keytool -genkey -v -keystore ~/polybius-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias polybius
cp android/key.properties.example android/key.properties   # then edit it
```

`key.properties` and `*.jks/*.keystore` are gitignored — never commit them.

## iOS

**Cannot be built on this Linux VM** — iOS compilation needs macOS + Xcode. The
project is fully configured for iOS, so on a Mac it builds with no extra setup:

```bash
# on macOS with Xcode installed:
flutter pub get
cd ios && pod install && cd ..          # or let `flutter build` do it
flutter build ios --release --no-codesign   # unsigned, for CI / sideloading
# or, signed, for TestFlight / App Store / on-device debug:
flutter build ipa --release             # needs an Apple Developer signing identity
```

The GitHub Actions `ios` job (`.github/workflows/release.yml`, `macos-latest`
runner) builds unsigned and packages a sideloadable **`polybius-ios-unsigned.ipa`**
(`Payload/Runner.app` layout).

**Config that makes this a real iOS port (not just the scaffold):**

- **Bundle id** `com.polybius.polybius`; display name **PØLYBĪUS** (`ios/Runner/Info.plist`).
- **Deployment target iOS 13.0** (`ios/Podfile` + `Runner.xcodeproj`). Driven by
  `audioplayers` (13.0); every other plugin is lower (`mobile_scanner` 12.0,
  `share_plus` 12.0, `flutter_secure_storage` 9.0).
- **Permissions / ATS** in `Info.plist`:
  - `NSCameraUsageDescription` — the QR **pool-sync scanner** (`mobile_scanner`).
    Without it iOS *terminates* the app the instant the camera opens.
  - `NSLocalNetworkUsageDescription` + `NSAppTransportSecurity →
    NSAllowsLocalNetworking` — lets the **Reticulum relay** reach a bridge on the
    LAN over `ws://` without disabling ATS globally.
  - `ITSAppUsesNonExemptEncryption = false` — skips the export-compliance prompt
    on every TestFlight/sideload build. **Re-evaluate before a public App Store
    submission**, since the app ships custom crypto.

**Per-plugin iOS status:** `flutter_secure_storage` → Keychain (genuinely
device-scoped here, unlike web/Linux); `audioplayers`, `share_plus`,
`mobile_scanner`, `qr_flutter`, `gamepads` (via `gamepads_ios` / GameController)
all have iOS implementations. The `gamepads` stream is guarded with `onError`, so
no-controller devices never crash. The **Reticulum mesh** has no in-app node on
iOS — `polybius_bridge.py` is a desktop companion — so on iOS the relay screen
lets you set the bridge's **LAN URL** (`ws://<host>:8765`, persisted) and shows
`MESH OFFLINE` until one is reachable.

**Sideloading the unsigned IPA** (no paid account needed for personal use):
AltStore / SideStore, Sideloadly, or TrollStore on supported iOS versions. A
free Apple ID gives a 7-day signing certificate; a paid Developer account or
TestFlight is needed for longer-lived installs.

---

## Security model — what is and isn't real (read before shipping)

**A Flutter app running on a device the user controls cannot cryptographically
enforce copy-protection.** Any client-side check can be bypassed by someone who
controls the binary and storage. The mechanisms below stop *forgery and
tampering* (real, useful) but do NOT stop a determined user from patching the
verifier out of their own copy — that needs a trusted server or hardware root
of trust the app does not have.

### Implemented (real signature verification)

Uses **Ed25519** detached signatures (`lib/core/crypto/signature_service.dart`).
The embedded verification key (`kProjectSigningPublicKeyB64`) is the Ed25519
public key of the developer's OpenPGP (curve 25519) key `0x24D2A8CD`. Only the
**public** half is in the app/repo; the private key never ships.

**Crypto-engine access is portal-only.** There is no cipher button on any
screen. The engine opens only by logging in at the dev access portal (reached
via the ritual: hold title 6s → difficulty 11 → Russian + hold SELECT 3s) with:
`B1-66-3R` or `D1-66-3R` (developer) · `Tr1-66-3R` (user-only, no dev panel) ·
or an invite token signed by the project key. To mint new signed user invite
tokens you sign with the Ed25519 seed of your key (see `polybius_sign.dart` /
the dev panel); the raw seed is NOT stored in the repo.

- **Signature-verified invite tokens.** A `SignedToken` binds a game file
  number + access tier + expiry, signed with the private key. The Load screen
  and Dev Access Portal verify the token (and expiry) against the trusted
  public key before honouring it. Forged codes are rejected because the private
  key isn't in the app.
- **Signature-verified update payloads.** `SignatureService.verifyPayload`
  checks a detached signature over a payload's SHA-256 before it would be
  applied. (Transport/apply is out of scope; the verification primitive is
  here.)
- **Trusted-key override (per-SD/USB keyset).** A dev can paste a different
  trusted public key in the developer panel; tokens are then verified against
  it (stored via `setTrustedPublicKey`).
- **Device-scoped data-at-rest.** The working AES key is derived
  `HMAC-SHA256(masterSecret, perInstallDeviceId)`. On native platforms the
  master lives in the OS keystore (`flutter_secure_storage`) so it is genuinely
  device-scoped; on web / keystore-less Linux (R36) it degrades to obfuscation.
  `EncryptionService.deviceBound` reports which.

### Minting signed invites / signing updates (dev, offline)

```bash
# One-time: generate your project keypair (replace the embedded public key).
dart run tool/polybius_keys.dart

# Mint a signed invite token (tier: user|agent|admin|developer):
dart run tool/polybius_sign.dart token <privateB64> PB-XXXX developer 30

# Sign an update payload file (prints a detached base64 signature):
dart run tool/polybius_sign.dart payload <privateB64> path/to/payload
```

The dev panel can also mint signed invites and store the signing key on the dev
device (secure storage). **The BETA keypair embedded in the app is for testing
only — regenerate and replace it for production.**

### Not achievable client-side (dropped / needs a server)

Preventing a user from reaching the cipher engine on their *own* device, and
truly blocking WiFi/SD updates, require a trusted server or hardware root of
trust. The "PGP-key-to-binary tool behind a dev password" is feasible as a
utility, but the dev password only gates the UI, not a cryptographic boundary.

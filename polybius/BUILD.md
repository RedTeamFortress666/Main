# PØLYBĪUS — BETA build guide

Version: `1.0.0-beta.1+1` (see `pubspec.yaml`).

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
   aarch64 GTK sysroot available to CMake).

**Controls on R36:** the handheld uses a d-pad/buttons (and a touchscreen on
the Max/Pro). The game supports **touch drag** and **WASD/arrow keys**;
physical gamepad button mapping is not yet wired up and is a follow-up before a
comfortable handheld BETA.

## Android

Prerequisites: Android SDK (via Android Studio or command-line tools), a JDK
(17+), and a **release keystore**.

```bash
flutter build apk --release        # single APK
flutter build appbundle --release  # Play/AAB
# output: build/app/outputs/
```

**Blocker for a real BETA:** `android/app/build.gradle.kts` currently signs
release builds with the **debug** keystore (fine for `flutter run --release`,
not acceptable for distribution). Create a keystore and a
`android/key.properties`, then wire a real `signingConfig` before shipping.

## iOS

**Cannot be built on this Linux VM.** Requires macOS + Xcode + an Apple
Developer account for signing/provisioning.

```bash
# on macOS:
flutter build ipa --release
```

Bundle id is `com.polybius.polybius`.

---

## Security model — what is and isn't real (read before shipping)

The request describes PGP-signed game copies, per-SD/USB key binding, and
gating updates to authorised dev accounts. **A Flutter app running on a device
the user controls cannot cryptographically enforce these properties.** Any
client-side check (invite validation, "is this copy signed", device binding)
can be bypassed by someone who controls the binary and storage. Treat the
current dev/crypto-engine gating as **obfuscation and defence-in-depth, not a
security guarantee.**

What *can* be implemented honestly (recommended design, not yet built):

- **Detached-signature invite codes.** Embed a project **public** key in the
  app; a dev signs invite codes / game-file-numbers with the matching private
  key; the app verifies the signature before unlocking. This genuinely stops
  forged invite codes (private key never ships), but does not stop a modified
  binary from skipping the check.
- **Signed update payloads.** Same idea for OTA/SD updates: verify a signature
  over the payload against the embedded public key before applying. Real
  protection against unauthorised update *content*, not against a user patching
  the verifier out.
- **Device-scoped data-at-rest.** Derive the storage key from a device secret
  (platform keystore/secure enclave where available) so copied data files
  won't decrypt on another device. On the R36 Linux handheld there is no secure
  element, so this degrades to a machine-id-derived key (obfuscation only).

What is **not** achievable client-side and should be dropped or moved
server-side: preventing a determined user from getting "past the video game
into the cryptography engine" on their own device, and truly preventing WiFi/SD
updates — those require a trusted server or hardware root of trust the app
does not have.

The **PGP-key-to-binary encryptor/decryptor behind a dev password** is feasible
as a utility (armored PGP <-> bytes), but the dev password only gates the UI; it
is not a cryptographic boundary on a user-controlled device.

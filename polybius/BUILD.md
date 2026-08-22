# PØLYBĪUS — BETA build guide

Version: `1.0.0-cherry.2+3` (see `pubspec.yaml`). Side-load APK: `downloads/polybius-darth-cherry.apk`.

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

**Cannot be built on this Linux VM.** Requires macOS + Xcode + an Apple
Developer account for signing/provisioning.

```bash
# on macOS:
flutter build ipa --release
```

Bundle id is `com.polybius.polybius`.

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

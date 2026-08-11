# PØLYBĪUS V1 STABLE

Offline beta is complete. Operator messages have been exchanged / decrypted via
QR pool sync. This cut ships two Android forks plus Darth-Cherry-gated identity
cards, an active Bluetooth link on CONNECT, and a redesigned Reticulum relay.

## Downloads

Raw GitHub links (branch `cursor/v1-stable-logins-ios-b952`):

### Android

| Artifact | URL |
| --- | --- |
| **PØLYBĪUS Portal — EMOJINIGMA HQ** (dev/admin, triple tier) | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-hq-android-arm64.apk |
| **PØLYBĪUS V1 (USER STABLE)** (operator/agent terminal) | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-user-android-arm64.apk |
| **DARTH CHERRY** (night red-light veil companion) | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/darth-cherry-1.0.2-android-arm64.apk |

### iOS (Safari web portable — Add to Home Screen)

Serve the unzipped folder over **https://** (not `file://`), then Safari → Share → Add to Home Screen.

| Artifact | URL |
| --- | --- |
| **Portal — EMOJINIGMA HQ** | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-hq-web-portable.zip |
| **V1 USER STABLE** | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-user-web-portable.zip |

### iOS (unsigned native IPA — sideload via AltStore / Sideloadly)

Produced by CI on `macos-latest`; unsigned — sign with your Apple ID.

| Artifact | URL |
| --- | --- |
| **Portal — EMOJINIGMA HQ** | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-hq-ios-unsigned.ipa |
| **V1 USER STABLE** | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/polybius-v1-stable-user-ios-unsigned.ipa |

Build locally:

```bash
cd polybius
flutter pub get

# EMOJINIGMA HQ fork (Portal APK)
flutter build apk --release --flavor hq --dart-define=POLYBIUS_FLAVOR=hq
# → build/app/outputs/flutter-apk/app-hq-release.apk

# Everyday user fork (V1 USER STABLE)
flutter build apk --release --flavor user --dart-define=POLYBIUS_FLAVOR=user
# → build/app/outputs/flutter-apk/app-user-release.apk

# iOS web portables (Linux/macOS)
flutter build web --release --dart-define=POLYBIUS_FLAVOR=hq
flutter build web --release --dart-define=POLYBIUS_FLAVOR=user
```

## Flavors

| Flavor | App label | Dart define | Capabilities |
| --- | --- | --- | --- |
| `hq` | **EMOJINIGMA HQ** | `POLYBIUS_FLAVOR=hq` | Agent + admin + developer unlock, HQ panel, cross encrypt/decrypt, full roster |
| `user` | **PØLYBĪUS** | `POLYBIUS_FLAVOR=user` | Portal → ENCRYPT / DECRYPT / POOL / SYNC / CONNECT (no HQ developer panel) |

## Operator identity cards

CONNECT → **OPERATOR IDENTITY CARDS**

- Without Darth Cherry: neon Illuminati / matrix eye + username + invite / game-file code
- With Darth Cherry overlay active: reveals that operator's password, backup password, and PIN

~~DEVELOPER / `developer`~~ is stricken — login returns `DEVELOPER ACCOUNT STRICKEN — V1 STABLE`.

## Login flow

1. **Arcade gate** (`/login`) — username + password → PIN if required → main menu
2. **Portal ritual** — hold title 6s → SETTINGS difficulty 11 → LANGUAGES Russian → hold SELECT 3s
3. **Dev Access Portal** (`/devportal`) — username + password + invite/dev code → cipher engine

All 23 bootstrapped operator accounts (dev/admin/agent) authenticate on first install.
See [`docs/OPERATOR_ACCOUNTS.md`](./OPERATOR_ACCOUNTS.md) and [`dist/operators/ADMIN_USER_POOL.txt.asc`](../dist/operators/ADMIN_USER_POOL.txt.asc).

## DARTH CHERRY

1. Install both the Polybius APK and `darth-cherry-1.0.2-android-arm64.apk`
2. DARTH CHERRY → grant overlay permission → ENABLE
3. Polybius → portal → cipher → ENCRYPT/DECRYPT reveals hidden eyeball under red veil
4. Tap eye = fade-type; hold 3s = matrix green veil

Android only — iOS uses operator identity cards without the overlay.

## Reticulum relay

CONNECT → **RETICULUM RELAY**

1. Connection strip at top (status + expand/collapse)
2. Scroll into connection details (bridge URL, your address, reconnect)
3. Outbound composer + inbound message bubbles

## Bluetooth

CONNECT → **BLUETOOTH LINK** toggle scans for nearby `POLYBIUS-*` devices, links a peer, and sends emoji ciphertext over GATT when a writable characteristic is present.

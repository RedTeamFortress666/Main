# PØLYBĪUS V1 STABLE

Offline beta is complete. Operator messages have been exchanged / decrypted via
QR pool sync. This cut ships two Android forks plus Darth-Cherry-gated identity
cards, an active Bluetooth link on CONNECT, and a redesigned Reticulum relay.

## Downloads

Raw GitHub links (branch `cursor/polybius-v1-wave3-accounts-21f4`, version **1.1.0+5**):

| Artifact | URL |
| --- | --- |
| **PØLYBÎŪS PORTAL / HQ** (24 dev/admin logins) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/polybius-v1-stable-hq-android-arm64.apk |
| **PØLYBÎŪS V.1 USER** (50 user logins) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/polybius-v1-stable-user-android-arm64.apk |
| **PØLYBÎŪS PORTAL — iOS** (Safari web portable) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/polybius-v1-stable-hq-ios-web-portable.zip |
| **PØLYBÎŪS V.1 — iOS** (Safari web portable) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/polybius-v1-stable-user-ios-web-portable.zip |
| DARTH CHERRY | https://github.com/RedTeamFortress666/Main/raw/cursor/v1-stable-logins-ios-b952/polybius/dist/darth-cherry-1.0.2-android-arm64.apk |

Aliases (same binaries):

- https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/POLYBIUS-V1-STABLE-hq-emojinigma-android-arm64.apk
- https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-wave3-accounts-21f4/polybius/dist/POLYBIUS-V1-STABLE-user-android-arm64.apk

Build locally:

```bash
cd polybius
flutter pub get

# PØLYBÎŪS PORTAL fork
flutter build apk --release --flavor hq --dart-define=POLYBIUS_FLAVOR=hq
# → build/app/outputs/flutter-apk/app-hq-release.apk

# PØLYBÎŪS V.1 (everyday user) fork
flutter build apk --release --flavor user --dart-define=POLYBIUS_FLAVOR=user
# → build/app/outputs/flutter-apk/app-user-release.apk
```

## Flavors

| Flavor | App label | Dart define | Capabilities |
| --- | --- | --- | --- |
| `hq` | **PØLYBÎŪS PORTAL** | `POLYBIUS_FLAVOR=hq` | Login gate, agent + admin + developer unlock, HQ panel, POOL vault, cross encrypt/decrypt. Ritual: diff 11 → **Russian** → lose → GAME OVER (diagnostic code unused) |
| `user` | **PØLYBÎŪS V.1** | `POLYBIUS_FLAVOR=user` | **Login gate** (user/agent accounts only). Ritual: early lose → hold **GAME OVER** → ERROR → **USER ACCESS PORTAL**. Tabs: ENCRYPT / DECRYPT / SYNC / CONNECT (no POOL) |

Both flavors require **Layer-1 operator login** (username + password + PIN). Accounts are **tier-gated by APK**:

| APK | Who can log in at startup |
| --- | --- |
| **PØLYBÎŪS PORTAL** | All **24** dev/admin accounts (8 developer + 16 admin) |
| **PØLYBÎŪS V.1 USER** | All **50** user/agent accounts |

Wrong APK for your tier shows a redirect message (e.g. user account on Portal → install V.1 USER).

Both flavors accept certified accounts for encrypt / decrypt / QR sync / Bluetooth after portal unlock.

## High scores

Players enter their **real name** on GAME OVER and on the HIGH SCORE board.
Pool-sync QR tokens (v2) carry each device's top scores; importing a peer's QR
merges boards so operators can compete across HQ and user builds.

## Operator identity cards

CONNECT → identity card button

| Viewer | Sees |
| --- | --- |
| **SpamKat2 / RedTeam01 / Gam3.0n** (DEV roster) | Full operator roster |
| Any other certified account | **Only their own** operator identity card |

- Without Darth Cherry: neon Illuminati / matrix eye + username + invite / game-file code
- With Darth Cherry overlay active: reveals password, backup password, and PIN for the visible card(s)

~~DEVELOPER / `developer`~~ is stricken — login returns `DEVELOPER ACCOUNT STRICKEN — V1 STABLE`.

## Reticulum relay

CONNECT → **RETICULUM RELAY**

1. Connection strip at top (status + expand/collapse)
2. Scroll into connection details (bridge URL, your address, reconnect)
3. Outbound composer + inbound message bubbles

## Bluetooth

CONNECT → **BLUETOOTH LINK** advertises a shared Polybius GATT service and scans
for peers on both **PORTAL (HQ)** and **V.1 (USER)** builds. Phones find each
other over the common service UUID (plus `POLYBIUS` name / manufacturer marker).

- Peer rail + ciphertext composer (`PB1|` envelopes)
- Message bubbles with **DECRYPT VIA CURRENT ROTOR**
- **SHARE ROTOR / POOL** — mutual 6-digit confirm before applying a pool
- Dual-role stack: `ble_peripheral` (GATT server) + `flutter_blue_plus` (central)

If sync/advertise fails: enable Bluetooth + nearby permissions; keep both apps
in the foreground with the link toggled on.

## Pool vault (leak prevention)

The **POOL** tab no longer shows the 560 emojis by default. Operators must enter
their **game file number** plus **6-digit PIN** to view the mapping. Encrypt,
decrypt, QR sync, and Bluetooth messaging remain available without opening the
vault.

## Cross-tier QR sync

User and HQ builds share the same `PoolSync` QR format. Any certified account
can randomise / scan / share a pool so encrypt↔decrypt round-trips across tiers.

## OPERATION VALKYRIE

PORTAL / HQ fail-safe. It wipes live invites, audit, and sessions, then
**relinks the certified operator roster** so V.1 USER agents can log in again
(including **PixelWiz** / `PIXELW1Z`, invite `PW9-66-3R`). Developer accounts
are kept; admin and agent seeds are restored to factory credentials.

**PixelWiz login aliases on V.1 USER:** `PixelWiz`, `PIXELWIZ`, `PIXELW1Z`,
or `PixelW1z` + password `PixelZap12` (backup `WizPixel5`) + PIN `367879`.

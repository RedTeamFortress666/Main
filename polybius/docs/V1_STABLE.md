# PØLYBĪUS V1 STABLE

Offline beta is complete. Operator messages have been exchanged / decrypted via
QR pool sync. This cut ships two Android forks plus Darth-Cherry-gated identity
cards, an active Bluetooth link on CONNECT, and a redesigned Reticulum relay.

## Downloads

Raw GitHub links (branch `cursor/polybius-v1-stable-8c69`):

| Artifact | URL |
| --- | --- |
| **PØLYBĪUS-V1-STABLE — EMOJINIGMA HQ** (Dev Admin, triple tier) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-stable-8c69/polybius/dist/polybius-v1-stable-hq-android-arm64.apk |
| **PØLYBĪUS-V1-STABLE — User** (ENCRYPT / DECRYPT / SYNC / CONNECT) | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-v1-stable-8c69/polybius/dist/polybius-v1-stable-user-android-arm64.apk |
| DARTH CHERRY | https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk |

Build locally:

```bash
cd polybius
flutter pub get

# EMOJINIGMA HQ fork
flutter build apk --release --flavor hq --dart-define=POLYBIUS_FLAVOR=hq
# → build/app/outputs/flutter-apk/app-hq-release.apk

# Everyday user fork
flutter build apk --release --flavor user --dart-define=POLYBIUS_FLAVOR=user
# → build/app/outputs/flutter-apk/app-user-release.apk
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

## Reticulum relay

CONNECT → **RETICULUM RELAY**

1. Connection strip at top (status + expand/collapse)
2. Scroll into connection details (bridge URL, your address, reconnect)
3. Outbound composer + inbound message bubbles

## Bluetooth

CONNECT → **BLUETOOTH LINK** toggle scans for nearby `POLYBIUS-*` devices across
HQ and user builds. The panel is a neo-noir cyberpunk messaging surface:

- Peer rail + ciphertext composer
- Message bubbles with **DECRYPT VIA CURRENT ROTOR**
- **SHARE ROTOR / POOL** — sends the current pool-sync token; both devices show
  a 6-digit onscreen code and must tap **CONFIRM CODE** before the receiver
  applies the pool

## Pool vault (leak prevention)

The **POOL** tab no longer shows the 560 emojis by default. Operators must enter
their **game file number** plus **6-digit PIN** to view the mapping. Encrypt,
decrypt, QR sync, and Bluetooth messaging remain available without opening the
vault.

## Cross-tier QR sync

User and HQ builds share the same `PoolSync` QR format. Any certified account
can randomise / scan / share a pool so encrypt↔decrypt round-trips across tiers.


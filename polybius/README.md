# PØLYBĪUS

Cross-platform covert encrypted messaging disguised as a janky retro 1980s psychedelic neon arcade space shooter.

## Platforms

- Android, iOS, GrapheneOS
- Windows, macOS, Linux desktop
- Web export (for emulation devices / SD-card Linux handhelds like R36S Ultra)
- **ESP32** — LilyGO T-Deck, LilyGO T-Embed S3, CYD, M5Stack Cardputer (`firmware/`)

## Quick Start

```bash
cd polybius
flutter pub get
flutter run          # mobile/desktop
flutter run -d chrome # web
```

**First login (V1 Stable):** use an operator account (e.g. `REDTEAM01` / `816639`).  
~~`DEVELOPER` / `developer`~~ is stricken.

## Flavors

```bash
# PØLYBÎŪS PORTAL (Dev Admin)
flutter run --flavor hq --dart-define=POLYBIUS_FLAVOR=hq

# PØLYBÎŪS V.1 (everyday user)
flutter run --flavor user --dart-define=POLYBIUS_FLAVOR=user
```

See `docs/V1_STABLE.md` for download links and operator cards.  
**Dev/admin only:** `docs/DEV_OPERATOR_MANUAL.md` (ops, OPSEC, mesh / hardware roadmap).

## Architecture

```
lib/
├── core/           # constants, crypto, models, storage, theme, widgets
├── features/
│   ├── auth/       # login gate + PIN re-auth
│   ├── arcade/     # decoy main menu, settings, load game
│   ├── cipher/     # Enigma-style emoji rotor engine + tabs
│   └── game/       # Flame space shooter (Galaga-inspired)
├── app.dart        # routing + CRT overlay
└── main.dart
```

## Three Layers

### Layer 1 — Login Gate
Operator login. V1 Stable bootstraps named operators + pool roster.
~~`DEVELOPER`~~ is retired.
### Layer 2 — Decoy Arcade
Psychedelic neon CRT main menu with playable space shooter. MKUltra-themed level names, subliminal glitch text, ship upgrades MK-I → MK-V.

### Layer 3 — Hidden Cipher
Multi-rotor Enigma variant. Each character → 2 emojis from a daily 560-emoji pool (date-seeded).

## Unlock Rituals

| Ritual | Steps | Result |
|--------|-------|--------|
| Portal (PORTAL APK) | Difficulty **11** → **Russian** → lose → hold GAME OVER → ERROR (6 words + draft SEND; diagnostic unused) | Access portal |
| Portal (V.1 APK) | Lose early → hold **GAME OVER** → ERROR (6 words + draft SEND) | Access portal |
| Title hold (legacy) | Hold title 6s | Still primes pathway |
| Dev codes | Portal login → `B1-66-3R` / `D1-66-3R` / `W1-66-3R` | Developer panel (privileged) |

## Cipher Tabs

- **🔒 ENCRYPT** — plaintext → emoji ciphertext
- **🔓 DECRYPT** — emoji → plaintext via current rotor / pool settings
- **🎲 POOL** — HQ only: 560-emoji vault (game file number + 6-digit PIN)
- **🔗 SYNC** — QR pool share/scan + high-score board merge across tiers
- **📡 CONNECT** — Bluetooth messaging, rotor/pool share with mutual confirm codes, relay, logout
- **⚙ Rotor Gear** — live rotor positions + decrypt-via-current-rotor

User APK: splash → arcade menu (no Layer-1 login). Ritual portal reads **USER ACCESS PORTAL**.

**Test matrix (credentials + rituals):** `docs/RITUAL_TEST_MATRIX.md`  
**Dev/admin ops manual:** `docs/DEV_OPERATOR_MANUAL.md`

## Build

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
flutter build linux      # Linux
flutter build web        # Web / emulation devices
```

## Tests

```bash
flutter test
```

## Security Notes

- Sensitive account data encrypted at rest (AES via `flutter_secure_storage`)
- Audit logging for all cipher operations and unlock attempts
- Dev shortcuts hidden in release builds (`kDebugMode`)
- Pool forcing logs out all users and requires PIN re-auth

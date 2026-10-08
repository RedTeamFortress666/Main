# PØLYBĪUS

Cross-platform covert encrypted messaging disguised as a janky retro 1980s psychedelic neon arcade space shooter.

## Platforms

- Android, iOS, GrapheneOS
- Windows, macOS, Linux desktop
- Web export (for emulation devices / SD-card Linux handhelds like R36S Ultra)

## Quick Start

```bash
cd polybius
flutter pub get
flutter run          # mobile/desktop
flutter run -d chrome # web
```

**First login:** `DEVELOPER` / `developer` (bootstrapped on first install)

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
Replit-style OIDC login. First install creates built-in `DEVELOPER` account.

### Layer 2 — Decoy Arcade
Psychedelic neon CRT main menu with playable space shooter. MKUltra-themed level names, subliminal glitch text, ship upgrades MK-I → MK-V.

### Layer 3 — Hidden Cipher
Multi-rotor Enigma variant. Each character → 2 emojis from a daily 560-emoji pool (date-seeded).

## Unlock Rituals

| Ritual | Steps | Result |
|--------|-------|--------|
| Title hold | Hold **PØLYBĪUS** title 3s | Hint state + fake crash |
| Difficulty 11 | SETTINGS → difficulty 11 + ENGLISH | Partial unlock |
| Compound | SETTINGS → difficulty 7 + RUSSIAN | Full cipher unlock |
| Invite code | LOAD GAME → valid `PB-XXXXXXXX` code | Cipher unlock |
| Dev codes | LOAD GAME → `B1-66-3R` or `D1-66-3R` + CHINESE language | Developer panel |

## Cipher Tabs

- **🔒 ENCRYPT** — plaintext → emoji ciphertext; **T3MP LINK** mints a temp.sh URL
- **🔓 DECRYPT** — emoji or a t3mp URL → plaintext
- **🎲 POOL** — today's 560-emoji cipher pool
- **🔗 SYNC** — randomise pool, QR, **T3MP LINK** (not GitHub gists)
- **📡 CONNECT** — device info, Bluetooth placeholder, logout
- **⚙ Rotor Gear** — live rotor positions and step counts

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

Sideload builds are shared as **t3mp** (`temp.sh`) links, not GitHub Releases.
See `RELEASES.md` and `downloads.html`.

## Security Notes

- Sensitive account data encrypted at rest (AES via `flutter_secure_storage`)
- Audit logging for all cipher operations and unlock attempts
- Dev shortcuts hidden in release builds (`kDebugMode`)
- Pool forcing logs out all users and requires PIN re-auth

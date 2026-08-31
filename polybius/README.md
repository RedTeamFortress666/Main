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

Five cabinets, one arcade. They do not share state except through the
providers in `lib/core/providers/app_providers.dart`.

```
lib/
├── core/                # constants, AES-at-rest, HKDF, hybrid envelope
├── features/
│   ├── auth/            # login gate + PIN (real or cover)
│   ├── arcade/          # decoy menu, high scores, settings
│   ├── cipher/          # rotors, pool manager, QR sync
│   ├── redlight/        # vanishing field + dual-layer keyboard
│   ├── duress/          # cover identity (in-memory session)
│   ├── transport/       # QR + Reticulum sidecar + Matrix fallback
│   └── game/            # Flame shooter
├── app.dart
└── main.dart
```

| Layer | Owns | Must not own |
|---|---|---|
| Arcade shell | CRT, scores, lamp chrome | Seeds, PINs, frames |
| Cipher engine | Rotors, 2/3-glyph map, stego decoys | UI, network |
| Pool manager | 24h draw, 2h remap | Transport |
| Redlight | Derangement, vanishing buffer | Ciphertext |
| Transport | Padded frames, RNS/Matrix/QR | Plaintext |

Honest limits: AES-256-GCM is the payload cipher (there is no AES-512).
X25519 is live. ML-KEM is a format slot, not an audited Kyber. Reticulum
is a loopback sidecar, not an embedded Python stack. Cover PIN sessions
look identical in the arcade; a Hive dump still shows that a cover record
exists. The leak detector names that residual. The auto-patcher weaves
cabinet policy (V2 ticket, phosphor mixer, real-seed chrome, V1 without
decoys, dual-density decrypt, cover PIN gate). It does **not** patch the
binary or hide a Hive dump.

## Three Layers

### Layer 1 — Login Gate
**PØLYBĪUS V2 protocol.** OPERATOR ID + ACCESS KEY, then a device-bound
session ticket (`v2:USER:issued:nonce:mac`). First install still creates
`DEVELOPER`. The handshake also runs the Darth Cherry leak sweep and
interwoven auto-patcher before the cabinet opens.

### Layer 2 — Decoy Arcade
Psychedelic neon CRT main menu with playable space shooter. MKUltra-themed level names, subliminal glitch text, ship upgrades MK-I → MK-V.

### Layer 3 — Hidden Cipher
Multi-rotor engine. Default **2 glyphs per character** (optional 3). Daily
master draw, remapped every 2 UTC hours. The second glyph is *not* the
plaintext index.

## Unlock Rituals

| Ritual | Steps | Result |
|--------|-------|--------|
| Title hold | Hold **PØLYBĪUS** title 3s | Hint state + fake crash |
| Difficulty 11 | SETTINGS → difficulty 11 + ENGLISH | Partial unlock |
| Compound | SETTINGS → difficulty 7 + RUSSIAN | Full cipher unlock |
| Invite code | LOAD GAME → valid `PB-XXXXXXXX` code | Cipher unlock |
| Dev codes | LOAD GAME → `B1-66-3R` or `D1-66-3R` + CHINESE language | Developer panel |
| Darth Cherry | LOAD GAME → `DARTH-CHERRY` or `CH3-RRY`, or Developer panel toggle | Glyph keyboard + leak detector + auto-patcher |

## Cipher Tabs

- **🔒 ENCRYPT** — advanced V1 plaintext field → emoji ciphertext (2 glyphs/char, no decoys). Glyph keyboard only after **Darth Cherry** is armed. Cherry shows the leak sweep.
- **🔓 DECRYPT** — emoji → plaintext
- **🎲 POOL** — active 560-glyph window + slot
- **🔗 SYNC** — QR / padded courier token
- **📡 CONNECT** — QR / RNS / Matrix status, logout
- **⚙ Rotor Gear** — odometer positions (notch is flavour only). **GEAR CAL** re-opens the PIN gate so a cover PIN can be entered while logged in.

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
- Pool forcing logs out all users (including DEVELOPER) and requires PIN re-auth
- V2 session tickets are HMAC-bound to the device key; they are not a password proof

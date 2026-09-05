# PØLYBĪUS

Cross-platform covert encrypted messaging disguised as a janky retro 1980s psychedelic neon arcade space shooter.

**Darth Cherry v3** uses hybrid ML-KEM-768 (Kyber) + AES-256-GCM. Private keys stay on-device. Ciphertext is a unique envelope, never an emoji pair that encodes plaintext indexes.

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

**First run:** there is no factory account. Tap **CREATE ACCOUNT**, choose an operator id, a password of 12+ characters, and a 6-digit PIN. Later accounts require a minted invite code.

## Architecture

```
lib/
├── core/           # constants, hybrid crypto, models, storage, theme, widgets
├── features/
│   ├── auth/       # login gate + PIN re-auth + portal passphrase
│   ├── arcade/     # decoy main menu, settings, load game
│   ├── cipher/     # Kyber+AES envelopes, unique QR, glyph keyboard
│   └── game/       # Flame space shooter (Galaga-inspired)
├── app.dart        # routing + CRT overlay
└── main.dart
```

## Three Layers

### Layer 1 — Login Gate
No bootstrapped credentials. First empty store creates the operator account. Restored sessions require the PIN.

### Layer 2 — Decoy Arcade
Psychedelic neon CRT main menu with playable space shooter. MKUltra-themed level names, subliminal glitch text, ship upgrades MK-I → MK-V.

### Layer 3 — Hidden Cipher (Darth Cherry v3)
Hybrid ML-KEM-768 encapsulation + AES-256-GCM. Each SEAL is a unique envelope (fresh Kyber ciphertext + nonce). The disappearing/rotating glyph keyboard maps cherry glyphs to latin characters in RAM for one pulse only. Unique DC3 QR frames never repeat a session id.

## Unlock Rituals

Portal and cipher routes are enforced in the **router**, not only by UI.

| Ritual | Steps | Result |
|--------|-------|--------|
| Title hold | Hold **PØLYBĪUS** title 6s | Primes `/devportal` (`pathwayPrimed`) |
| Compound | SETTINGS → difficulty 11 + RUSSIAN + hold SELECT | Opens portal **if** primed |
| Portal passphrase | Set/enter a 12+ character passphrase on the account | Grants session cipher access |

There are **no** compiled passwords, PINs, or access codes. Invites mint accounts; they do not open the cipher. Cipher unlock is session-only (cleared on logout).

## Cipher Tabs

- **ENCRYPT** — glyph keyboard → unique QR of a Kyber+AES envelope (no plaintext clipboard)
- **DECRYPT** — scan unique QR / paste envelope → local `open()` with the device private key
- **POOL** — Kyber fingerprints only (no emoji pool, no seed)
- **SYNC** — unique QR of the **public** key; scan a peer public key
- **CONNECT** — device info, Bluetooth placeholder, logout

## Confidentiality bar

- Ciphertext does not encode plaintext indexes; pool/seed never appear in UI, QR, or clipboard.
- No default password, PIN, or access code in source or binaries.
- `/cipher` and `/devportal` are router-gated.
- No debug-signed APK in git; CI requires release signing secrets.
- Secrets at rest use AES-256-GCM. Native builds use the platform keystore (`flutter_secure_storage`). **Web localStorage is a hard limit** — treat web as a preview, not a confidentiality target.

## Build

```bash
flutter build apk --release   # requires android/key.properties (see BUILD.md)
flutter build ios
flutter build windows
flutter build macos
flutter build linux
flutter build web
```

## Tests

```bash
flutter test
```

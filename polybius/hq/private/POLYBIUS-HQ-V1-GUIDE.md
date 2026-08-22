# PØLYBĪUS HQ / V1 — private operator guide

This file is the complete HQ sheet for User V1 + Darth Cherry on branch
`cursor/floating-glyph-keyboard-b248`. It is stored on the private repository
only. Network-node and resurrection procedures are **not** in this file.

**Encrypted admin pack** (Reticulum nodes, Matrix/Element, Operation Valkyrie):

`polybius/hq/private/polybius-admin-valkyrie.zip`

Unlock that zip with the HQ lock phrase issued out of band
(`YouWearYourMotherAsAHat`). Do not put the phrase on the public landing page.

Private file URL (repo collaborators):

https://github.com/RedTeamFortress666/Main/blob/cursor/floating-glyph-keyboard-b248/polybius/hq/private/POLYBIUS-HQ-V1-GUIDE.md

https://github.com/RedTeamFortress666/Main/blob/cursor/floating-glyph-keyboard-b248/polybius/hq/private/polybius-admin-valkyrie.zip

---

## 1. What ships in V1

| Piece | Where | Notes |
| --- | --- | --- |
| Arcade shooter | `/menu` → START GAME | Flame space shooter |
| Login gate | `/login` | `DEVELOPER` / `developer` |
| Clock | `/clock` | Factory code `oneeyedking`, force change |
| Analog 24h | `/clock/face` | Roman I–XXIV |
| Cherry desk | `/clock/desk` | Notes, typebox, set-share QR |
| Glyph keys | `/clock/keys` | `A POLYBĪUS SQU\R3` floating keys |
| Cipher engine | `/cipher` | Portal-only after rituals |

APK: `polybius/downloads/polybius-darth-cherry.apk` · `1.0.0-cherry.1+2`

## 2. Arcade and portal (existing product)

### First accounts

- Built-in: `DEVELOPER` / `developer`, default PIN `000000`
- Register creates an agent-tier account (does not auto-login)

### Cipher is portal-only

No cipher button on the start screen. Reach the portal:

1. Hold the **PØLYBĪUS** title **6 seconds** (pathway primed)
2. SETTINGS → difficulty **11**
3. LANGUAGES → **RUSSIAN**, hold SELECT **3 seconds**
4. Dev access portal login + a code:
   - `B1-66-3R` or `D1-66-3R` → developer (engine + panel)
   - `Tr1-66-3R` / `TR1-66-3R` → user engine, no panel
   - or a signed invite token (`PB-XXXXXXXX` / `SignedToken`)

Other documented rituals (see `README.md` / `unlock_codes.dart`):

| Ritual | Result |
| --- | --- |
| Title hold 3s | Hint + fake crash |
| Difficulty 11 + ENGLISH | Partial |
| Difficulty 7 + RUSSIAN | Full cipher unlock (compound) |
| LOAD GAME + valid invite | Cipher unlock |
| LOAD GAME `B1-66-3R`/`D1-66-3R` + CHINESE | Developer panel |

### Cipher tabs

ENCRYPT, DECRYPT, POOL, SYNC (QR pool align), CONNECT (device info; Bluetooth is a placeholder).

Pool sync tokens are base64url JSON (`v`, `pid`, `s`, `e`, `h`), 6-hour window, SHA-256 integrity over the 560-emoji pool.

### Signing (dev)

```bash
cd polybius
dart run tool/polybius_keys.dart
dart run tool/polybius_sign.dart token <privateB64> PB-XXXX developer 30
```

The BETA key in-tree is for testing. Rotate for production. Private seeds are not in the repo.

## 3. Clock / Cherry (V1 additions)

### Clock code

- Factory: `oneeyedking`
- Stored as PBKDF2 in Hive settings (`clockPwHash`)
- `clockPwChanged` is false until the operator sets a new code (min 4 chars, not the factory string)

### Open the desk

All four must be true, then **hold SET ALARM 3s**:

1. Analog hour **5**, minute **11**
2. Alarm string normalizes to **`V XIXI`**
3. **DARTH CHERRY** switch on
4. Hold duration 3 seconds

Wrong combo → `Alarm saved` only.

### Desk controls

| Control | Action |
| --- | --- |
| MAKE hold 2s | Typebox clears after 800 ms |
| MAKE QR? paste / CREATE+CUT | session key `PBK-` + 32-byte base64url |
| Camera cherry hold 3s | FLAG_SECURE + typebox dump → AES-CBC/HMAC (`polybius-keyboard-qr`) → PBK1 frames |
| SCAN KEYBOARD / keys SCAN | assemble PBK1, open only with the same session key |
| ?∞ tap then hold 2s | `/clock/face` + false ALARM (`V XIXI`) |
| SLEEP double-tap | `/clock/keys` |
| STOP double-tap | lock clock session, `/clock` |

### Alphabet pool

Seeded steg + hieroglyph + sigil sets. Same seed → same glyphs. Token `v: 2` with set names. Randomise / share / scan from the desk.

## 4. Build and test

```bash
cd polybius
flutter pub get
flutter test          # 52 tests on this branch at last count
flutter analyze
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Flutter **3.44.8** / Dart **3.12.2**. Android SDK 35/36, JDK 17+. Without `android/key.properties`, release APKs are **debug-signed**.

Web (this VM):

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## 5. What CONNECT is not (yet)

`ConnectTab` Bluetooth is UI-only. Reticulum transports and Matrix/Element bridging are specified in the **encrypted admin pack**, not in the Flutter tree.

## 6. Security facts (do not oversell)

A device-owned Flutter binary cannot stop the owner from patching checks. What *is* real:

- AES-CBC v2 payloads with random IVs
- PBKDF2 password/PIN hashes
- Ed25519 invite/update verification against the embedded public key
- Device-bound AES on platforms with a real keystore
- Clock factory-code upgrade on first open

Web / keystore-less Linux: at-rest crypto degrades to obfuscation (`EncryptionService.deviceBound`).

## 7. File map (HQ)

```
polybius/
  downloads/polybius-darth-cherry.apk
  hq/public/index.html
  hq/public/USER-V1-DARTH-CHERRY.md
  hq/private/POLYBIUS-HQ-V1-GUIDE.md    ← this file
  hq/private/polybius-admin-valkyrie.zip
  lib/features/clock/                    ← face, desk, keys, pools
  lib/features/cipher/                   ← engine, sync, portal
```

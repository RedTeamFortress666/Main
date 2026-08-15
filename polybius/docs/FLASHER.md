# PØLYBÎŪS Android Flasher (hardened 1.5)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets — and other Android phones — without a PC.

| Target | Action |
| --- | --- |
| **R36S** | Detect common ports roots, prepare/format SD (FAT write probe), Direct or PortMaster **autoinstall**, verify `Polybius.sh` + `polybius/` |
| **CYD classic / CYD2USB / ESP32-32E / Generic ESP32** | Presets for Bruce/Launcher-friendly boards; merged `polybius-cyd.bin` @ `0x0`; guided BOOT/RESET; TEST CONNECTION; optional serial capture |
| **LilyGO T-Deck** | `polybius-tdeck.bin` · esp32s3 · prefer Skip auto-reset · trackball download-mode wizard |
| **Android (OTG ADB)** | Selective multi-APK install (Portal / V.1 / Darth Cherry bundled); MTP detection; per-APK `pm` errors; continue queue; optional `-d` / `--user 0` |

- App source: [`../../polybius_flasher/`](../../polybius_flasher/)
- Package id: `com.polybius.flasher`
- Dist APK: [`../dist/polybius-flasher-1.5.1-android-arm64.apk`](../dist/polybius-flasher-1.5.1-android-arm64.apk)
- Launcher icon: Fat Man–style bomb with stencil **GAME ØN**

## Hardening highlights

- SHA-256 verification on every bundled `.bin` / `.zip` / `.apk` materialize
- Structured EventChannel events: `{stage, percent, message, level, target, detail, ts, ok}` + **COPY LOGS**
- All USB / ADB / SAF / flash work off the UI thread; cancellable; battery / short-cable warning before OTG
- USB permission re-request on replug; live device re-resolve (no stale handles)

## Bundled core APKs (operator-selected)

| App | File |
| --- | --- |
| **PØLYBÎŪS PORTAL** | `polybius-v1-stable-hq-android-arm64.apk` |
| **PØLYBÎŪS V.1 USER** | `polybius-v1-stable-user-android-arm64.apk` |
| **DARTH CHERRY 1.0.2** | `darth-cherry-1.0.2-android-arm64.apk` |

Check one, some, or **SELECT ALL BUNDLED** — nothing installs unless selected.

## Operator checklist

### Android OTG
1. Enable USB debugging on TARGET; connect data OTG (host = flasher).
2. **RE-SCAN DEVICES** → authorize RSA prompt on target.
3. If inventory says MTP only → switch USB mode / enable debugging.
4. Select APK(s) → **INSTALL APK** / **INSTALL N APKS**.
5. Queue continues on non-fatal `pm` failures; summary shows `INCOMPATIBLE` / `VERSION_DOWNGRADE` / etc.

### R36S
1. Prefer **Prepare SD before install**.
2. Pick SAF folder → choose detected root (`roms/ports`, `roms2/ports`, `EASYROMS/ports`, …).
3. Mode: **Direct** or **Autoinstall**.
4. Verify report must show `Polybius.sh` + `polybius/`.

### CYD / ESP32-32E
1. Read overwrite warning (full image replaces Launcher/Bruce).
2. **TEST CONNECTION** first; if sync fails, follow BOOT→RESET guided sheet.
3. Flash @ `0x0`; optional 1500 ms serial capture.

### T-Deck
1. Prefer Skip auto-reset.
2. Hold trackball BOOT + RST until black screen → CONTINUE.
3. After write, RST out of download mode.

## Build

```bash
cd polybius_flasher
flutter pub get
flutter test
flutter analyze
flutter build apk --release --target-platform=android-arm64
```

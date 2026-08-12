# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets and other Android phones:

| Target | What it does |
| --- | --- |
| **R36S** | Prepare/format SD (FAT32/exFAT) then unzip PortMaster port into `roms/ports/` |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` |
| **ESP32-32E 240×320 Resistive** | Same CYD firmware on classic ESP32 + 2.8″ resistive panels |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 USB-JTAG) |
| **Android (OTG ADB)** | Send bundled Portal + V.1 USER + Darth Cherry (or any catalog/local APK) over USB OTG / TCP ADB |

Package id: `com.polybius.flasher` · Version **1.4.0**

## Bundled APKs

- `assets/apks/polybius-v1-stable-hq-android-arm64.apk` — Portal
- `assets/apks/polybius-v1-stable-user-android-arm64.apk` — V.1 USER
- `assets/apks/darth-cherry-1.0.2-android-arm64.apk` — Darth Cherry

## T-Deck download mode (important)

Android often cannot auto-reset Espressif USB-Serial/JTAG (`VID 303a PID 1001`).

1. Hold the **trackball center** (BOOT).
2. Power on / press **RST** while holding.
3. Keep holding 2–3s until the screen stays black.
4. In the flasher, choose **I already put the device in download mode — Skip**.

## Build

```bash
cd polybius_flasher
flutter pub get
flutter test
flutter build apk --release --target-platform=android-arm64
```

Dist: `polybius/dist/polybius-flasher-1.4.0-android-arm64.apk`

See [`../polybius/docs/FLASHER.md`](../polybius/docs/FLASHER.md).

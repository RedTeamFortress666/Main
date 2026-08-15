# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets and other Android phones:

| Target | What it does |
| --- | --- |
| **R36S** | SD (SAF path detect + Direct/Autoinstall) or **USB stick** (`POLYBIUS_R36S_USB/`) + optional custom ROM |
| **CYD / ESP32-32E** | Presets (classic / CYD2USB / 32E / generic) + manual BOOT/RESET wizard |
| **LilyGO T-Deck** | Dedicated ESP32-S3 preset + trackball download-mode UX |
| **Android (OTG ADB)** | Selective multi-APK over USB OTG / TCP with SHA-256 + pm error surfacing |

Package id: `com.polybius.flasher` · Version **1.5.1**

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

Dist: `polybius/dist/polybius-flasher-1.5.2-android-arm64.apk`

See [`../polybius/docs/FLASHER.md`](../polybius/docs/FLASHER.md).

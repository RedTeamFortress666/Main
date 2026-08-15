# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets and other Android phones:

| Target | What it does |
| --- | --- |
| **R36S** | SD (SAF path detect + Direct/Autoinstall) or **USB stick** (`POLYBIUS_R36S_USB/`) + optional custom ROM |
| **CRYPT3X OS LITE** | Stage the official **8 GiB** GPT image (or 921 MiB `.img.zip`) onto a USB stick as `CRYPT3X_OS_LITE/`, SHA-256 verified. Flash the card with `dd` on a PC (`tool/flash_crypt3x_lite.sh`). Not bundled in the APK. |
| **CYD / ESP32-32E** | Presets (classic / CYD2USB / 32E / generic) + manual BOOT/RESET wizard |
| **LilyGO T-Deck** | Dedicated ESP32-S3 preset + trackball download-mode UX |
| **Android (OTG ADB)** | Selective multi-APK over USB OTG / TCP with SHA-256 + pm error surfacing |

Package id: `com.polybius.flasher` · Version **1.6.0**

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

Download (arm64, 1.6.0):
https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.6.0-android-arm64.apk

Dist: `polybius/dist/polybius-flasher-1.6.0-android-arm64.apk`

## CRYPT3X OS LITE (8 GiB)

The packed image is 8 GiB (`lineage-18.1-20260815-1244-r36s-crypt3x-lite.img`). Flutter cannot ship that inside an APK. Catalog + SHA-256 live in `assets/r36s/crypt3x-lite.json` and `lib/crypt3x_lite.dart`.

1. Copy the `.img` or `.img.zip` onto the phone (Downloads).
2. In the flasher: **CRYPT3X OS LITE** → **PICK .IMG / .ZIP** → **PICK USB STICK**.
3. Raw `.img` needs **exFAT** (FAT32 max file is 4 GiB). The 921 MiB zip fits FAT32.
4. **WRITE CRYPT3X OS LITE** stages `CRYPT3X_OS_LITE/` with README, FLASH.txt, and SHA256.txt.
5. On a PC, `dd` the raw image onto the R36S SD:

```bash
polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX
```

Do not commit the 8 GiB binary. Host builds land at `/opt/android/andr36oid/device/gameconsole/r36s/`.

See [`../polybius/docs/FLASHER.md`](../polybius/docs/FLASHER.md).

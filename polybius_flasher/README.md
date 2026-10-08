# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets and other Android phones:

| Target | What it does |
| --- | --- |
| **R36S** | Lists every filename required inside `polybius-r36s-port.zip`, then writes SD (SAF) or USB stick (`POLYBIUS_R36S_USB/`). Verify `Polybius.sh` + `polybius/`. |
| **CRYPT3X OS LITE** | Stage a picked `.img`/`.img.zip` as `CRYPT3X_OS_LITE/`, **or** concatenate `part00`–`part11` into `CRYPT3X_ETCHER/` for balenaEtcher / Rufus. SHA-256 verified. Phone cannot `dd` GPT. |
| **CYD / ESP32-32E** | Presets (classic / CYD2USB / 32E / generic) + manual BOOT/RESET wizard |
| **LilyGO T-Deck** | Dedicated ESP32-S3 preset + trackball download-mode UX |
| **Android (OTG ADB)** | Selective multi-APK over USB OTG / TCP with SHA-256 + pm error surfacing |

Package id: `com.polybius.flasher` · Version **1.8.0**

## Downloads

- Flasher APK 1.8.0: https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.8.0-android-arm64.apk
- R36S PortMaster zip: https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-r36s-port.zip
- Backup zip path: https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius_flasher/assets/r36s/polybius-r36s-port.zip
- Previous flasher 1.7.0: https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.7.0-android-arm64.apk

Required filenames + fallbacks (Etcher / PortMaster / manual copy): [`docs/R36S_ALTERNATE_FLASH.md`](docs/R36S_ALTERNATE_FLASH.md).

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

Download (arm64, 1.8.0):
https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.8.0-android-arm64.apk

Dist: `polybius/dist/polybius-flasher-1.8.0-android-arm64.apk`

## CRYPT3X OS LITE (8 GiB)

The packed image is 8 GiB (`lineage-18.1-20260815-1244-r36s-crypt3x-lite.img`). Flutter cannot ship that inside an APK. Catalog + SHA-256 live in `assets/r36s/crypt3x-lite.json` and `lib/crypt3x_lite.dart`.

### Stage a picked image

1. Copy the `.img` or `.img.zip` onto the phone (Downloads).
2. In the flasher: **CRYPT3X OS LITE** → **PICK .IMG / .ZIP** → **PICK USB STICK**.
3. Raw `.img` needs **exFAT** (FAT32 max file is 4 GiB). The 921 MiB zip fits FAT32.
4. **WRITE CRYPT3X OS LITE** stages `CRYPT3X_OS_LITE/` with README, FLASH.txt, and SHA256.txt.

### Prepare an Etcher / Rufus kit from the 12 parts

1. Put `CRYPT3X_OS_LITE-r36s-20260815.zip.part00`–`part11` in one folder on the phone.
2. **PREPARE ETCHER / RUFUS KIT** → pick that folder → pick the USB stick.
3. The flasher concatenates the parts into `CRYPT3X_ETCHER/` (SHA-256 verified) and writes `ETCHER.txt`, `RUFUS.txt`, `FLASH.txt`.
4. On a PC, open balenaEtcher on the assembled zip, or Rufus in **DD Image** mode on the unzipped `.img`.

On a PC without the phone:

```bash
polybius_flasher/tool/prepare-crypt3x-etcher-kit.sh /path/to/parts
polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX
```

Do not commit the 8 GiB binary. Host builds land at `/opt/android/andr36oid/device/gameconsole/r36s/`.

Card write steps (Etcher / `dd` / Rufus DD): [`../device_r36s_polybius/FLASH_R36S.md`](../device_r36s_polybius/FLASH_R36S.md).
Rebuild the 921 MiB zip only: `tool/assemble-crypt3x-lite-zip.sh`.

See [`../polybius/docs/FLASHER.md`](../polybius/docs/FLASHER.md).

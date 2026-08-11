# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets:

| Target | What it does |
| --- | --- |
| **R36S** | Unzips the PortMaster port into an SD card `roms/ports/` tree via SAF |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 USB-JTAG) |

Package id: `com.polybius.flasher` · Version **1.1.0**

## T-Deck download mode (important)

Android often cannot auto-reset Espressif USB-Serial/JTAG (`VID 303a PID 1001`).

1. Hold the **trackball center** (BOOT).
2. Power on / press **RST** while holding.
3. Keep holding 2–3s until the screen stays black.
4. In the flasher, choose **I already put the device in download mode — Skip**.

The app also tries classic DTR/RTS, inverted lines, and a **1200-baud touch** before giving up.

## Flash options

- Full image `@ 0x0` (default) / app-only `@ 0x10000` / custom address
- Chip: `esp32` / `esp32s3`
- Baud: 115200 → 921600 (start low on S3)
- Erase entire flash · hard reset after write · **Test connection only**

## Build

```bash
cd polybius_flasher
flutter pub get
flutter test
flutter build apk --release --target-platform=android-arm64
```

Dist: `polybius/dist/polybius-flasher-1.1.0-android-arm64.apk`

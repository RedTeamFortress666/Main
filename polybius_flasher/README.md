# PØLYBÎŪS FLASHER (Android)

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets:

| Target | What it does |
| --- | --- |
| **R36S** | Unzips the PortMaster port into an SD card `roms/ports/` (or `roms2/ports/`) tree via Storage Access Framework |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` (ESP32 app image @ `0x10000`) |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 app image @ `0x10000`) |

Package id: `com.polybius.flasher`

## Requirements

- Android 7+ phone/tablet with **USB host (OTG)**
- USB-C OTG adapter + data cable
- For ESP targets: board already has a bootloader (normal for CYD / T-Deck). First-ever blank chips still need a PC `pio upload` once.
- For R36S: microSD mounted on the phone (USB reader or built-in), ArkOS / JELOS / similar with a `roms/ports` folder

## Build

```bash
cd polybius_flasher
flutter pub get
flutter build apk --release --target-platform=android-arm64
```

APK lands at `build/app/outputs/flutter-apk/app-release.apk`.
Dist copy: `polybius/dist/polybius-flasher-1.0.0-android-arm64.apk`.

## ESP flash tips

1. Select **CYD** or **T-Deck**, plug the board in, **RESCAN**, grant USB permission.
2. Tap **FLASH**.
3. If sync fails: hold **BOOT**, tap **RESET**, keep BOOT held until the console says `Synced`.
4. Image is written at **0x10000** (application partition). Bootloader + partition table are left alone.

## R36S tips

1. Select **R36S** → **FLASH**.
2. When the folder picker opens, choose the SD card **`roms`** folder (or `roms/ports` directly).
3. On the handheld: **Ports → Polybius**.

Bundled assets:

- `assets/firmware/polybius-cyd.bin`
- `assets/firmware/polybius-tdeck.bin`
- `assets/r36s/polybius-r36s-port.zip` (from `polybius/dist/polybius-1.0.0-beta.1-r36s-port.zip`)

# PØLYBÎŪS Android Flasher

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets without a PC.

| Target | Action |
| --- | --- |
| **R36S** | Unzips the PortMaster port into SD `roms/ports/` (or `roms2/ports/`) via SAF |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` (ESP32 app @ `0x10000`) |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 app @ `0x10000`) |

- App source: [`../../polybius_flasher/`](../../polybius_flasher/)
- Package id: `com.polybius.flasher`
- Dist APK: [`../dist/polybius-flasher-1.1.0-android-arm64.apk`](../dist/polybius-flasher-1.1.0-android-arm64.apk)

## Requirements

- Android 7+ with USB host (OTG)
- OTG adapter + data cable for ESP boards
- ESP boards must already have a bootloader (normal for CYD / T-Deck). Blank chips still need a one-time PC `pio upload`.
- For R36S: microSD readable by the phone; pick the `roms` or `roms/ports` folder

## Operator flow

1. Sideload `polybius-flasher-1.1.0-android-arm64.apk`.
2. Open **PØLYBÎŪS FLASHER**.
3. Select target → **FLASH**.
4. ESP: grant USB permission; if sync fails, hold **BOOT**, tap **RESET**.
5. R36S: pick the SD `roms` / `ports` tree when prompted; launch **Ports → Polybius** on the handheld.

## PC fallback

```bash
cd polybius/firmware
pio run -e cyd -t upload
pio run -e tdeck -t upload
```


## T-Deck tip (1.1)

If sync times out on cmd `0x08`, hold trackball BOOT, reset, then use **Skip auto-reset** in the flasher.
Default flash address is now **0x0** (full image).

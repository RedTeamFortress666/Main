# ESP32 firmware binaries

Built from `polybius/firmware` (PlatformIO).

| File | Board |
| --- | --- |
| `polybius-tdeck.bin` | LilyGO T-Deck |
| `polybius-tembed.bin` | LilyGO T-Embed S3 |
| `polybius-cyd.bin` | CYD ESP32-2432S028 |
| `polybius-cardputer.bin` | M5Stack Cardputer |

Flash with `pio run -e <env> -t upload` (preferred), `esptool.py`, or the
**Android flasher** (`polybius_flasher` / `polybius-flasher-*-android-arm64.apk`)
which writes the app image at `0x10000` over USB-OTG.
See `../../firmware/README.md` and `../../docs/FLASHER.md`.

### Cardputer flash (esptool)

```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 write_flash 0x0 polybius-cardputer.bin
```

Or from the firmware tree: `pio run -e cardputer -t upload`.

# ESP32 firmware binaries

Built from `polybius/firmware` (PlatformIO).

| File | Board |
| --- | --- |
| `polybius-tdeck.bin` | LilyGO T-Deck |
| `polybius-tembed.bin` | LilyGO T-Embed S3 |
| `polybius-cyd.bin` | CYD ESP32-2432S028 |

Flash with `pio run -e <env> -t upload` (preferred) or `esptool.py`.
See `../../firmware/README.md`.

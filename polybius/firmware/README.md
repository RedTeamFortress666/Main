# PØLYBĪUS ESP32 firmware

Offline emoji-cipher client for:

| Env (`pio run -e …`) | Hardware | Input |
| --- | --- | --- |
| `tdeck` | LilyGO **T-Deck** (ESP32-S3, 320×240) | Physical keyboard + USB serial |
| `tembed` | LilyGO **T-Embed S3** (170×320) | Rotary encoder + USB serial |
| `cyd` | **CYD** ESP32-2432S028 (240×320) | Touch + USB serial |

The cipher engine is a **byte-compatible** port of the Flutter `CipherEngine` /
`DailyPool` / `PoolSync` stack (same pools, rotors, and ciphertext as the phone
app for a shared seed). Host golden tests lock this in without hardware.

## Quick start

```bash
# Host golden tests (no ESP32 needed)
cd polybius/firmware
make test

# Build firmware (PlatformIO)
pio run -e tdeck
pio run -e tembed
pio run -e cyd

pio run -e tdeck -t upload
pio device monitor -b 115200
```

## Serial protocol

Every board exposes a USB serial shell:

```
unlock 000000
seed 2026-07-22
complexity 2
enc HELLO
dec <emoji ciphertext>
pool
sync
import <pool-sync-token>
```

Default PIN is `000000` (also accepts `B1-66-3R`). Use `sync` / `import` to
align with a phone running PØLYBĪUS (same token format as the Flutter SYNC tab).

## Layout

```
firmware/
├── include/polybius/   # cipher + UI headers
├── include/boards/     # pin maps
├── src/cipher/         # Dart-compatible engine
├── src/ui/             # TFT + serial shell
├── src/main.cpp
├── test/               # host golden tests
├── platformio.ini
└── Makefile            # host tests
```

## Notes

- T-Deck / T-Embed require the peripheral **power-on** GPIO driven HIGH.
- T-Embed here targets the **S3** revision (GPIO46 power, ST7789 SPI). Classic
  ESP32 T-Embed pinouts differ — adjust `board_pins.h` / `platformio.ini`.
- CYD touch coordinates vary by panel revision; use serial if taps feel off.
- Arcade decoy, Red Veil, and Reticulum are **not** ported — cipher + pool sync only.

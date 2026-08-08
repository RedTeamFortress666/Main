# POLYBIUS PRESS — image / SD organiser

Local-first workshop for staging microSD layouts and ESP32 firmware before flash.

## Devices

| Group | Profiles | Dual options |
|-------|----------|--------------|
| **R36S** | ArkOS, ROCKNIX, LineageOS (AndR36oid) | Single · Dual card (OS+ROMs) · Dual OS swap |
| **ESP32** | LilyGO T-Deck, M5Stack Cardputer, T-Embed, CYD | Single · Dual firmware (reflash) · Dual card (firmware + FAT SD assets)* |

\* Dual card on ESP32 only when the board has a microSD slot (T-Deck, Cardputer).

## Web UI

```bash
npm install
npm run dev   # http://localhost:5173
```

## CLI

```bash
python tools/sd_organiser/sd_organiser.py list-profiles

# R36S Lineage + TF2 ROMs
python tools/sd_organiser/sd_organiser.py stage \
  --profile r36s-lineage --mode dual_card --polybius --out ./stage/r36s-lineage

# Cardputer dual firmware (POLYBIUS + alternate .bin)
python tools/sd_organiser/sd_organiser.py stage \
  --profile m5-cardputer --mode dual_firmware --out ./stage/cardputer

# T-Deck firmware + microSD assets
python tools/sd_organiser/sd_organiser.py stage \
  --profile lilygo-tdeck --mode dual_card --out ./stage/tdeck

# Destructive SD flash (R36S .img only — not ESP32 .bin)
sudo python tools/sd_organiser/sd_organiser.py flash \
  --image ./stage/r36s-lineage/downloads/os-image.img \
  --disk /dev/sdX
```

ESP32 firmware flashes with `esptool` / PlatformIO — see `FLASH*.txt` in the staged folder.

## LineageOS on R36S

1. Clean install image from [andr36oid/release_uploads](https://github.com/andr36oid/release_uploads) (not OTA).
2. Stage + flash TF1; first boot often reformats f2fs.
3. Use TF2 for ROMs; sideload Polybius APK from stage notes.

## Tests

```bash
npm test
python -m py_compile tools/sd_organiser/sd_organiser.py
```

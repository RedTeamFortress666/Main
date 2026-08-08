# POLYBIUS PRESS — SD image organiser

Local-first workshop for staging microSD layouts before flashing handheld OS images.

## Web UI

```bash
npm install
npm run dev   # http://localhost:5173
```

Choose a device (R36S ArkOS / ROCKNIX / **LineageOS AndR36oid**, or LilyGO T-Deck), a boot layout, and optionally include POLYBIUS payloads. The UI builds a checklist, folder tree, and flash commands — it does not upload files.

### Boot layouts (R36S)

| Mode | Meaning |
|------|---------|
| **Single card** | One microSD with the full OS image in TF1 |
| **Dual card** | TF1 = OS image, TF2 = ROMs / extras after first boot |
| **Dual OS swap** | Two OS cards (e.g. Lineage + ArkOS); swap the card in TF1 to switch OS |

R36S does not dual-boot two OS images from one card the way a PC EFI menu does — dual boot here means **two physical cards**.

## LineageOS on R36S

1. Download a **clean install** image from [andr36oid/release_uploads](https://github.com/andr36oid/release_uploads) (not an OTA zip).
2. Stage: `python tools/sd_organiser/sd_organiser.py stage --profile r36s-lineage --mode dual_card --polybius --out ./stage/r36s-lineage`
3. Decompress to `.img`, then flash TF1 with Etcher, Rufus, or the CLI `flash` command.
4. First boot reformats (often f2fs). Then use TF2 for ROMs.
5. Sideload `polybius-*-android-arm64.apk` from the stage `sideload/` notes.

Optional: place an empty `.noroms` on the BOOT partition before first boot to allocate storage to Android.

## CLI

```bash
python tools/sd_organiser/sd_organiser.py list-profiles

python tools/sd_organiser/sd_organiser.py stage \
  --profile r36s-lineage \
  --mode dual_os_swap \
  --polybius \
  --out ./stage/lineage-dual

# Destructive — confirms the disk path
sudo python tools/sd_organiser/sd_organiser.py flash \
  --image ./stage/lineage-dual/downloads/os-image.img \
  --disk /dev/sdX
```

Safety: `flash` refuses common system disks (`/dev/sda`, `nvme0n1`, …) unless `--i-know-what-im-doing` is set, requires typing the disk path (or `-y`), and expects a decompressed `.img`.

## Tests

```bash
npm test
python -m py_compile tools/sd_organiser/sd_organiser.py
```

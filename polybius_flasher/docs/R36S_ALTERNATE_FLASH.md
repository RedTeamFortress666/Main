# R36S flash — required files and fallbacks

A PortMaster zip flashes successfully only if it contains **every** path in
`assets/r36s/iso-manifest.json`. The official package is
`polybius-r36s-port.zip` (SHA-256
`58f7ae8a90f4fc0d74e51c0931949cd5e698a9f62663c4d65c777978765e2493`).

## Downloads

| File | Primary (GitHub, logged-in) | Backup |
| --- | --- | --- |
| Flasher APK 1.8.0 | [`polybius/dist/polybius-flasher-1.8.0-android-arm64.apk`](https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.8.0-android-arm64.apk) | Cursor artifact `polybius-flasher-1.8.0-android-arm64.apk`; previous `polybius-flasher-1.7.0-android-arm64.apk` |
| PortMaster zip | [`polybius/dist/polybius-r36s-port.zip`](https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-r36s-port.zip) | [`polybius_flasher/assets/r36s/polybius-r36s-port.zip`](https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius_flasher/assets/r36s/polybius-r36s-port.zip) · **also bundled inside the APK** |
| CRYPT3X OS LITE GPT zip | not on GitHub (921 MiB) | Cursor artifacts `CRYPT3X_OS_LITE-r36s-20260815.zip.part00`–`part11` + `CRYPT3X_OS_LITE-r36s-20260815.zip.SHA256SUMS`. Phone: **PREPARE ETCHER / RUFUS KIT**. PC: `tool/prepare-crypt3x-etcher-kit.sh` |

GitHub raw 404s when logged out (private repo). Use the artifacts if that happens.

## Names the zip must contain

Must-verify (flasher / PortMaster will refuse otherwise):

- `ports/Polybius.sh`
- `ports/polybius/polybius`
- `ports/polybius/lib/libapp.so`
- `ports/polybius/lib/libflutter_linux_gtk.so`

Plus every other path listed in the ISO manifest (gptk, ICU, Flutter assets, plugins, audio). Missing any of them yields a black screen or a missing-port error.

## If the custom flasher fails

### A. Manual copy (does not erase ArkOS / JELOS)

1. Unzip `polybius-r36s-port.zip` on a PC.
2. Copy `ports/Polybius.sh` and the `ports/polybius/` folder onto the SD:
   - ArkOS / JELOS: `roms/ports/`
   - some ROCKNIX: `roms2/ports/`
   - some images: `EASYROMS/ports/`
3. Eject, boot the R36S, open **Ports → Polybius**.

### B. PortMaster autoinstall

Copy `polybius-r36s-port.zip` (the zip itself, not the unzipped tree) to:

- `roms/ports/autoinstall/` **or**
- `PortMaster/autoinstall/`

Reboot or launch PortMaster. It unpacks the zip.

### C. Full OS image (erases the card) — Etcher / Rufus / `dd`

Use CRYPT3X OS LITE, not the PortMaster zip. See [`../../device_r36s_polybius/FLASH_R36S.md`](../../device_r36s_polybius/FLASH_R36S.md).

```bash
# phone flasher: CRYPT3X OS LITE → PREPARE ETCHER / RUFUS KIT
# or on a PC:
polybius_flasher/tool/prepare-crypt3x-etcher-kit.sh .
# balenaEtcher / Raspberry Pi Imager / Rufus DD mode on CRYPT3X_ETCHER/*.zip
# or:
sudo dd if=lineage-18.1-20260815-1244-r36s-crypt3x-lite.img \
  of=/dev/sdX bs=4M status=progress conv=fsync
```

Do **not** `cp` the `.img` onto a formatted card. Do **not** treat the PortMaster zip as a disk ISO.

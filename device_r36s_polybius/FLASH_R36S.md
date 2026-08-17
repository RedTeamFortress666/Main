# Flash CRYPT3X OS LITE onto an R36S

This is a **GPT disk image** for a microSD card, not a CD/DVD ISO.
Use balenaEtcher, Raspberry Pi Imager, Rufus (DD mode), or `dd`.
Do **not** mount it and copy files onto an existing ArkOS/JELOS card.

| | |
| --- | --- |
| Build | `lineage_r36s_crypt3x_lite-userdebug` · `20260815-1244` |
| Zip | `lineage-18.1-20260815-1244-r36s-crypt3x-lite.img.zip` · **921 MiB** |
| Zip SHA-256 | `67493055e6bfad6a3c14b40b2723d19550eef99fde16cc23bf0250fdd7b61b38` |
| Image | `lineage-18.1-20260815-1244-r36s-crypt3x-lite.img` · **8.0 GiB** |
| Image SHA-256 | `ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc` |
| Card | **32 GB** or larger microSD (image is 8 GiB; first boot uses the unused tail for userdata) |

**This erases the entire card.** Confirm the device name before you write.

## 1. Get the zip

The flash file is **one zip** (8 GiB `.img` + `FLASH_R36S.txt`).
GitHub and the artifact store both reject a single 921 MiB object, so the
zip is published as twelve ≤80 MiB parts. One `cat` rebuilds the zip:

```bash
cat CRYPT3X_OS_LITE-r36s-20260815.zip.part00 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part01 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part02 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part03 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part04 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part05 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part06 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part07 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part08 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part09 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part10 \
    CRYPT3X_OS_LITE-r36s-20260815.zip.part11 \
    > CRYPT3X_OS_LITE-r36s-20260815.zip

sha256sum CRYPT3X_OS_LITE-r36s-20260815.zip
# expect e79ac4225e702c3b5b5dc353198522be2141c2d6f20c8ec9df6f8cb548428f93
```

Windows (PowerShell):

```powershell
cmd /c copy /b CRYPT3X_OS_LITE-r36s-20260815.zip.part00+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part01+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part02+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part03+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part04+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part05+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part06+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part07+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part08+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part09+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part10+`
  CRYPT3X_OS_LITE-r36s-20260815.zip.part11 `
  CRYPT3X_OS_LITE-r36s-20260815.zip
```

## 2. Unzip

```bash
unzip CRYPT3X_OS_LITE-r36s-20260815.zip
# FLASH_R36S.txt, SHA256SUMS.txt, and the 8 GiB .img
sha256sum lineage-18.1-20260815-1244-r36s-crypt3x-lite.img
# expect ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc
```

Etcher / Raspberry Pi Imager can take the assembled **zip** or the raw `.img`.
Rufus: extract the `.img`, then write in **DD** mode.

## 3. Write the card

### Linux (`dd`)

```bash
lsblk   # find the microSD, e.g. /dev/sdb — not a partition like /dev/sdb1
sudo umount /dev/sdX* || true
# optional checked writer (types FLASH to confirm):
polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX
# or:
sudo dd if=lineage-18.1-20260815-1244-r36s-crypt3x-lite.img \
  of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

### macOS

```bash
diskutil list
diskutil unmountDisk /dev/diskN
sudo dd if=lineage-18.1-20260815-1244-r36s-crypt3x-lite.img \
  of=/dev/rdiskN bs=4m
sync
```

Use `rdiskN` (raw) not `diskN`.

### Windows

1. Insert the microSD (USB reader).
2. Open **balenaEtcher** or **Raspberry Pi Imager**.
3. Select `lineage-18.1-20260815-1244-r36s-crypt3x-lite.img` or the `.img.zip`.
4. Select the microSD. Flash. Eject.

Rufus: choose the `.img`, **DD Image** mode, write, eject.

The phone **PØLYBÎŪS FLASHER** has two CRYPT3X actions:

- **WRITE CRYPT3X OS LITE** — stage a picked `.img` / `.img.zip` as `CRYPT3X_OS_LITE/`.
- **PREPARE ETCHER / RUFUS KIT** — concatenate `part00`–`part11` into `CRYPT3X_ETCHER/`
  with `ETCHER.txt`, `RUFUS.txt`, `FLASH.txt`, and `SHA256.txt`.

It cannot `dd` GPT onto the R36S card. Finish on a PC (Etcher / Rufus DD / `dd`).
On a PC you can also run `polybius_flasher/tool/prepare-crypt3x-etcher-kit.sh`.

## 4. Boot the R36S

1. Power the handheld **off**.
2. Seat the card in the R36S microSD slot (the OS slot, not a secondary ROMs slot).
3. Power on. First boot can take a few minutes (userdata on the unused tail).
4. You should get the CRYPT3X boot animation, then the vault desk
   (Mail / F-Droid / Brave / Cherry).

If it drops back to ArkOS/JELOS, the card is in the wrong slot or was not
written as a raw disk image.

## Notes

- FAT32 cannot hold the raw 8 GiB `.img`. Keep it zipped, or use exFAT, to copy
  the file around. Flashing does not need FAT32 — `dd` / Etcher write the GPT.
- Do not `cp` the `.img` onto a formatted card. That is not a flash.
- Factory vault duress PIN is documented in `device_r36s_polybius/README.md`.
  Change the vault PIN at first setup. Do not use an operator PIN as duress.

# PØLYBÎŪS Android Flasher

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets — and other Android phones — without a PC.

| Target | Action |
| --- | --- |
| **R36S** | **Prepare/format SD** (FAT32/exFAT write probe + `roms/ports` layout), then unzip the PortMaster port via SAF |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` (default full image @ `0x0`) |
| **ESP32-32E 240×320 Resistive** | Same CYD firmware on classic ESP32 + 2.8″ resistive (CYD-compatible) |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 USB-JTAG, @ `0x0`) |
| **Android (OTG ADB)** | Send **Portal / V.1 USER / Darth Cherry** (bundled offline) — plus catalog APKs — onto another phone over USB OTG ADB (or TCP ADB) |

- App source: [`../../polybius_flasher/`](../../polybius_flasher/)
- Package id: `com.polybius.flasher`
- Dist APK: [`../dist/polybius-flasher-1.4.1-android-arm64.apk`](../dist/polybius-flasher-1.4.1-android-arm64.apk)

## Bundled core suite (offline)

These ship inside the flasher APK under `assets/apks/`:

| App | File |
| --- | --- |
| **PØLYBÎŪS PORTAL** | `polybius-v1-stable-hq-android-arm64.apk` |
| **PØLYBÎŪS V.1 USER** | `polybius-v1-stable-user-android-arm64.apk` |
| **DARTH CHERRY 1.0.2** | `darth-cherry-1.0.2-android-arm64.apk` |

Enable **SELECT ALL BUNDLED** (or check individual boxes) on the Android OTG
target to choose Portal, V.1, and/or Darth Cherry — the flasher installs only
what you select.

## Requirements

- Android 7+ with USB host (OTG)
- OTG adapter + data cable for ESP boards / phone-to-phone
- ESP boards must already have a bootloader (normal for CYD / T-Deck / ESP32-32E). Blank chips still need a one-time PC `pio upload`.
- For R36S: microSD readable by the phone, formatted **FAT32 or exFAT**; pick the `roms` or `roms/ports` folder
- For **Android OTG ADB**: target phone with **USB debugging** enabled; authorize this flasher’s RSA key on first connect; use a data-capable OTG cable (host = flasher phone)

## Operator flow

1. Sideload `polybius-flasher-1.4.1-android-arm64.apk`.
2. Open **PØLYBÎŪS FLASHER**.
3. Select target → **FLASH** / **INSTALL APK** / **INSTALL N APKS**.
4. ESP: grant USB permission; follow on-screen BOOT/RESET instructions (or Skip if already in download mode).
5. R36S:
   - Prefer **Prepare SD before flash** (default on).
   - Optional **Logical format** wipes the selected tree, then recreates `roms/ports`.
   - Use **SYSTEM FORMAT SETTINGS** if the card is NTFS/ext4 / unreadable — format as FAT32/exFAT, then return.
   - Pick the SD `roms` / `ports` tree; launch **Ports → Polybius** on the handheld.
6. Android OTG: check **one or more** catalog APKs (or pick a local `.apk`), connect the target over OTG, authorize debugging, tap **INSTALL APK**. Optional: TCP ADB (`adb tcpip 5555`) instead of USB.

## SD prepare / format notes

Android apps cannot run privileged block-level `mkfs` without system permissions. The flasher therefore:

1. Probes writable access (rejects non-FAT-compatible mounts).
2. Optionally logically formats (deletes contents of the selected tree).
3. Creates the PortMaster `roms/ports` (or ESP `polybius/`) layout and a readiness marker.
4. Deep-links to system storage settings when a full OS-level format is required.

OS images for TF1 (ArkOS / ROCKNIX / Lineage) still need POLYBIUS PRESS / a PC `dd` — this tool prepares the **ports/ROMs** volume and flashes the Port zip.

## ESP32-32E / T-Deck tips

- **ESP32-32E:** Hold BOOT → press/release RESET → release BOOT; keep BOOT until Syncing… Default baud **460800**, address **0x0**.
- **T-Deck:** If sync times out on cmd `0x08`, hold trackball BOOT, reset, then use **Skip auto-reset**.

## Android OTG notes

- Uses embedded AdbLib (USB + TCP) — push to `/data/local/tmp/` then `pm install -r`.
- Core suite APKs (**Portal / V.1 / Darth Cherry**) are **bundled** (no network needed). The operator selects which of them (or other catalog entries) to install — nothing is pushed unless checked. Other catalog entries download from `polybius/dist/` and cache under app documents.
- First connection shows the target’s “Allow USB debugging?” dialog — accept it or the handshake hangs until cancelled.

## PC fallback

```bash
cd polybius/firmware
pio run -e cyd -t upload
pio run -e tdeck -t upload
```

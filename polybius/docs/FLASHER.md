# PØLYBÎŪS Android Flasher

Phone-side installer for shipping PØLYBĪUS onto handheld / MCU targets — and other Android phones — without a PC.

| Target | Action |
| --- | --- |
| **R36S** | Unzips the PortMaster port into SD `roms/ports/` (or `roms2/ports/`) via SAF |
| **CYD ESP32-2432S028** | USB-OTG serial flash of `polybius-cyd.bin` (default full image @ `0x0`) |
| **ESP32-32E 240×320 Resistive** | Same CYD firmware on classic ESP32 + 2.8″ resistive (CYD-compatible) |
| **LilyGO T-Deck** | USB-OTG serial flash of `polybius-tdeck.bin` (ESP32-S3 USB-JTAG, @ `0x0`) |
| **Android (OTG ADB)** | Install Portal / V.1 / Doomsday / Darth Cherry / etc onto another phone over USB OTG ADB (or TCP ADB) |

- App source: [`../../polybius_flasher/`](../../polybius_flasher/)
- Package id: `com.polybius.flasher`
- Dist APK: [`../dist/polybius-flasher-1.3.0-android-arm64.apk`](../dist/polybius-flasher-1.3.0-android-arm64.apk)

## Requirements

- Android 7+ with USB host (OTG)
- OTG adapter + data cable for ESP boards
- ESP boards must already have a bootloader (normal for CYD / T-Deck / ESP32-32E). Blank chips still need a one-time PC `pio upload`.
- For R36S: microSD readable by the phone; pick the `roms` or `roms/ports` folder
- For **Android OTG ADB**: target phone with **USB debugging** enabled; authorize this flasher’s RSA key on first connect; use a data-capable OTG cable (host = flasher phone)

## Operator flow

1. Sideload `polybius-flasher-1.3.0-android-arm64.apk`.
2. Open **PØLYBÎŪS FLASHER**.
3. Select target → **FLASH** / **INSTALL APK**.
4. ESP: grant USB permission; follow on-screen BOOT/RESET instructions (or Skip if already in download mode).
5. R36S: pick the SD `roms` / `ports` tree when prompted; launch **Ports → Polybius** on the handheld.
6. Android OTG: pick a catalog APK (downloaded+cached) or a local `.apk`, connect the target over OTG, authorize debugging, tap **INSTALL APK**. Optional: TCP ADB (`adb tcpip 5555`) instead of USB.

## ESP32-32E / T-Deck tips

- **ESP32-32E:** Hold BOOT → press/release RESET → release BOOT; keep BOOT until Syncing… Default baud **460800**, address **0x0**.
- **T-Deck:** If sync times out on cmd `0x08`, hold trackball BOOT, reset, then use **Skip auto-reset**.

## Android OTG notes

- Uses embedded AdbLib (USB + TCP) — push to `/data/local/tmp/` then `pm install -r`.
- Catalog APKs are fetched from the repo `polybius/dist/` raw URLs and cached under app documents.
- First connection shows the target’s “Allow USB debugging?” dialog — accept it or the handshake hangs until cancelled.

## PC fallback

```bash
cd polybius/firmware
pio run -e cyd -t upload
pio run -e tdeck -t upload
```

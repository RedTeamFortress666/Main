PØLYBĪUS — R36S / RK3326 handheld port
======================================

WHAT THIS IS
------------
This is the aarch64 (ARM64) Linux build of PØLYBĪUS packaged as a "Port" that
drops into an existing R36S-class firmware (ArkOS, ROCKNIX, JELOS, AmberELEC,
etc.). It is NOT a bootable OS image / ".iso" — the R36S boots its own firmware
from the SD card, and games/apps are added on top as ports.

INSTALL
-------
1. Flash a stock R36S firmware to your SD card if you don't have one already
   (ArkOS or ROCKNIX are the common choices — download from their official
   sources and write the .img with Balena Etcher / Rufus / dd).
2. Put the SD card in a card reader on your PC (or use the device's file share).
3. Copy the contents of this package's "ports" folder into your firmware's
   ports directory:
       /roms/ports/            (single-SD firmwares)
       /roms2/ports/           (some dual-SD setups)
   After copying you should have:
       <ports>/Polybius.sh
       <ports>/polybius/polybius        (the ARM64 executable)
       <ports>/polybius/lib/ ...        (engine + plugins)
       <ports>/polybius/data/ ...       (assets)
4. Put the card back in the R36S, refresh the games list (or reboot), open the
   PORTS collection, and select "Polybius".

CONTROLS
--------
- D-pad / left stick: move.  A: fire/confirm.  B: back/escape.  Start: enter.
- The build also reads the hardware gamepad natively via /dev/input. If a
  button feels wrong, edit polybius/polybius.gptk (gptokeyb keymap) or the
  in-game mapping (see the project's BUILD.md, _onGamepadEvent).

FIRST LOGIN
-----------
Username: DEVELOPER   Password: developer

TROUBLESHOOTING
---------------
- A log is written to Polybius.log next to Polybius.sh on each launch. If the
  game doesn't appear, read that file first.
- This is a GTK/OpenGL desktop app. RK3326 devices have a Mali GPU with limited
  GL support, so the native app may not render on every firmware. If it fails,
  the log usually shows an EGL/GL or X error. In that case use the WEB build as
  a fallback: serve the polybius-web bundle and open it in the device browser,
  or play on a phone/PC.
- Treat this as a BETA that is UNVERIFIED on physical R36S hardware.

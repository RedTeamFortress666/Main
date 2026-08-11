# GÅMÊ-ØVĒR Pentest Suite

Mobile-first **authorized engagement console** for [GÅMÊ-ØVĒR Cyber Solutions](https://github.com/RedTeamFortress666/Main).

## What this is

A React + Vite operator UI for customer/lab pentests:

- Attack module grid (scanner, NetHunter, portals, WiFi, BLE, BadUSB, IR, payloads, devices)
- Kali NetHunter bridge panel (tool catalog + heartbeat simulation)
- ESP32 Bluetooth / USB-serial device picker (Bruce-compatible command link UI)
- Evil Portal lab builder → HTML edit/preview → T-Deck flash queue (simulated)
- Captures log with sample data + CSV export
- WiFi arsenal board with attack-device selection

**This build does not execute real exploits, deauth frames, credential theft, or HID payloads.** Actions are simulated so you can demo the console and later wire your private NetHunter / ESP32 / Bruce backends.

## Run

```bash
npm install
npm run dev      # http://localhost:5173
npm run test
npm run lint
npm run build
```

## Android packaging

Wrap the Vite build with Capacitor (or Cordova) when you are ready for Play / sideload:

```bash
npm run build
# npx cap add android && npx cap sync android
```

Pair real hardware later via:

- NetHunter chroot / ADB bridge
- ESP32 BLE (Bruce / Marauder profiles)
- USB-C serial (CH340 / CP2102) direct line
- LilyGO T-Deck SD flash for portal artifacts

## Legal

For authorized security research and contracted customer assessments only. Obtain explicit written permission before testing any system you do not own.

# CRYPT3X OS (`lineage_r36s_crypt3x`)

Named fork of AndR36oid / LineageOS 18.1 for the R36S. Do **not** fork
`BoardConfig.mk` or the kernel tree. Hardware bring-up stays in
`device/gameconsole/common`.

Boot sequence (5.5s): rotating gears with clicks → keyhole of light →
black type **Brought to you by GÅMÊ ØVĒR**. Rebuild with:

```bash
python3 device_r36s_polybius/media/render_bootanim.py
```

Lunch: `lineage_r36s_crypt3x-userdebug` (`lineage_r36s_polybius-*` is an alias).

## Why a new product

| | `lineage_r36s` (stock) | CRYPT3X OS |
| --- | --- | --- |
| Launcher | Daijishou | Doomsday Clock vault (HOME) |
| Browser | Cromite | Cromite (kept) |
| Extra apps | game-fronted | Polybius + optional Orbot/WireGuard |
| GApps | inherit-if-exists | explicitly overridden away |
| Screen | stay-on 24h | 2 min timeout |
| Bluetooth | off at boot | on (mesh) |
| USB serial | ACM/serial off in kernel | ACM + FTDI/CP210x/CH340 |

Stock remains buildable: `lunch lineage_r36s-userdebug`.

## Apply into the live device tree

```bash
./device_r36s_polybius/apply.sh
```

That copies these files to `device/gameconsole/r36s/`, enables USB ACM/serial
in `lineageos_r36s_defconfig`, and adds `/dev/ttyACM*` to common `ueventd`.

## Drop / fetch APKs

```bash
./device_r36s_polybius/fetch-apks.sh
```

That pulls from `cursor/v1-stable-logins-ios-b952`:

| Module | applicationId | Role |
| --- | --- | --- |
| Polybius | `com.polybius.polybius.user` | V1 USER STABLE (operators) |
| PolybiusHq | `com.polybius.polybius.hq` | EMOJINIGMA HQ (portal/admin) |
| DoomsdayClock | `com.polybius.doomsday_clock` | Calendar vault 2.0.2 (HOME) |

APKs are gitignored. Different package IDs, so user + HQ both preinstall.
Doomsday Clock 2.0.2 is HOME: it replaces Daijishou/Trebuchet. Ritual OPEN
launches concealed `com.polybius.polybius.user` (no player/APK cards).
Strip drawer icons after a fresh fetch:

```bash
./device_r36s_polybius/conceal-prebuilts.sh
```

Optional Orbot/WireGuard still drop in by hand.

## Build (after a full Lineage sync — ask before downloading)

```bash
source build/envsetup.sh
lunch lineage_r36s_crypt3x-userdebug
mka -j$(nproc) bootimage systemimage
cd device/gameconsole/r36s && sudo ./mkimg.sh
```

Docker:

```bash
BUILD_TARGET=lineage_r36s_crypt3x-userdebug docker compose up
```

## What this does / does not do

Already in stock AndR36oid (kept):

- Cromite prebuilt (Tor/SOCKS/custom DNS capable)
- BLE + classic BT (`android.hardware.bluetooth@1.1-service.btlinux`)
- Wi-Fi Direct permission + `p2p_supplicant.conf`
- USB host + accessory + `config_disableUsbPermissionDialogs`
- Audio HAL, Panel 0–6 DTBs (default Panel 4 in `mkimg.sh`)
- `ro.config.low_ram=true`, no Scudo, Go-style ART
- No phone stack (Telecom/Telephony already removed)

Added by this product:

- New lunch target and prebuilt slots
- Strip Daijishou / gallery / music / camera / print / GMS names
- USB ACM + USB-UART kernel options (needed for ESP32-S3 CDC)
- `init.polybius.rc` + `polybius_bridge.py` reference
- Battery-friendlier SettingsProvider defaults
- Files app packaged (OTG storage)

Not in the AndR36oid tree today (do not invent them in the ROM):

- Reticulum / `rns` / `lxmf` — not present. Run later via Termux or a
  native `polybius_bridge` binary talking to `rnsd`.
- System-wide “force all traffic through Tor” without a VPN app.
  Use Orbot VPN mode + always-on VPN. Cromite SOCKS is per-app.
- Python on `/system` — the bridge script is a reference only.

## Files you will edit later

| File | When |
| --- | --- |
| `prebuilts/*/Name.apk` | APKs arrive |
| `permissions/privapp-permissions-polybius.xml` | vault package name known |
| `scripts/polybius_bridge.py` | real WS/serial/Reticulum gateway |
| `polybius/android/app/src/main/AndroidManifest.xml` | rebuild APKs without LAUNCHER |
| `kernel/.../lineageos_r36s_defconfig` | extra radios / HID quirks |
| `device/gameconsole/r36s/mkimg.sh` | only if panel default should change |

Do not edit `device/gameconsole/common/device.mk` for app policy — that file
is shared with stock `lineage_r36s` and R50S/R46H-style siblings.

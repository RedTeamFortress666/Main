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
Lite (under 16GB image for a 32GB SD): `lineage_r36s_crypt3x_lite-userdebug`.

## Why a new product

| | `lineage_r36s` (stock) | CRYPT3X OS |
| --- | --- | --- |
| Launcher | Daijishou | Vault HOME — Mail / F-Droid / Brave / Cherry |
| Browser | Cromite | Brave (Cromite removed) |
| Extra apps | game-fronted | Proton Mail, F-Droid, Darth Cherry, concealed Polybius |
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
./device_r36s_polybius/fetch-cover-apks.sh
```

| Module | applicationId | Role |
| --- | --- | --- |
| ProtonMail | `ch.protonmail.android` | Desk mail |
| FDroid | `org.fdroid.fdroid` | Desk catalogue (adaptability) |
| Brave | `com.brave.browser` | Desk browser + default http(s) |
| DarthCherry | `com.polybius.red_veil` | Desk — Darth Cherry 1.0.2 |
| Polybius | `com.polybius.polybius.user` | Concealed (ritual OPEN) |
| PolybiusHq | `com.polybius.polybius.hq` | Concealed HQ (omitted on lite) |
| DoomsdayClock | `com.polybius.doomsday_clock` | HOME 2.0.4+6 — desk + Cherry + duress |

The public home is four apps. Route sets Android 11 Private DNS, MAC
randomization, and scan/location/captive-portal flags. F-Droid is how you
add or replace anything later without flashing.

Duress PIN (vault lock, PIN field): factory default `737380`. The UI still
says ACCESS DENIED, then userdata is factory-reset. Change it at first
vault setup. Do not pick an operator PIN.

```bash
./device_r36s_polybius/conceal-prebuilts.sh
```

Optional Orbot/WireGuard still drop in by hand for a device-wide IP path.

## Build (after a full Lineage sync)

Host driver (dedicated tree at `/opt/android/andr36oid`, Java 11, 32GiB swap, `-j2`):

```bash
./device_r36s_polybius/mka-lite.sh
```

Override `ANDROID_ROOT`, `BUILD_JOBS`, or `REPO_SYNC_JOBS` as needed. Log: `/opt/android/mka-lite.log`.

Manual, after sync:

```bash
source build/envsetup.sh
lunch lineage_r36s_crypt3x_lite-userdebug
mka -j$(nproc) bootimage systemimage
cd device/gameconsole/r36s && sudo ./mkimg_lite.sh   # 8GiB, under 16GiB
```

**Flash a card:** see [`FLASH_R36S.md`](FLASH_R36S.md). Download the single
zip `CRYPT3X_OS_LITE-r36s-20260815.zip` from the run artifacts (GitHub cannot
host 921 MiB). Write the inner `.img` with Etcher / Raspberry Pi Imager /
Rufus (DD) or:

```bash
polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX
```

The phone flasher (**PØLYBÎŪS FLASHER → CRYPT3X OS LITE**) only *stages*
the zip onto a USB stick. It cannot `dd` GPT. Finish on a PC.

Sideload kit (no full sync — APKs onto a device that already boots):

```bash
./device_r36s_polybius/pack-lite-testkit.sh
```

Docker:

```bash
BUILD_TARGET=lineage_r36s_crypt3x-userdebug docker compose up
```

## What this does / does not do

Already in stock AndR36oid (kept):

- BLE + classic BT (`android.hardware.bluetooth@1.1-service.btlinux`)
- Wi-Fi Direct permission + `p2p_supplicant.conf`
- USB host + accessory + `config_disableUsbPermissionDialogs`
- Audio HAL, Panel 0–6 DTBs (default Panel 4 in `mkimg.sh`)
- `ro.config.low_ram=true`, no Scudo, Go-style ART
- No phone stack (Telecom/Telephony already removed)

Added by this product:

- New lunch target and prebuilt slots (Brave, F-Droid, Proton Mail)
- Strip Daijishou / Cromite / gallery / music / camera / print / GMS names
- Android 11 hardening defaults (Quad9 DoT fallback, no captive portal, no Play verifier)
- USB ACM + USB-UART kernel options (needed for ESP32-S3 CDC)
- `init.polybius.rc` + `polybius_bridge.py` reference
- Battery-friendlier SettingsProvider defaults
- Files app packaged (OTG storage)

Not in the AndR36oid tree today (do not invent them in the ROM):

- Reticulum / `rns` / `lxmf` — not present. Run later via Termux or a
  native `polybius_bridge` binary talking to `rnsd`.
- System-wide “force all traffic through Tor” without a VPN app.
  Use Orbot VPN mode + always-on VPN. Brave is per-app until then.
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

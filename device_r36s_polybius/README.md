# CRYPT3X OS (`lineage_r36s_crypt3x`)

Named fork of AndR36oid / LineageOS 18.1 for the R36S. Do **not** fork
`BoardConfig.mk` or the kernel tree. Hardware bring-up stays in
`device/gameconsole/common`.

This tree is **privacy-first**: no Google services, no Lineage stats, no
captive-portal probes, ADB off, USB grants explicit, radios off until the
user enables them. See [`SECURITY_AUDIT.md`](SECURITY_AUDIT.md).

Boot sequence (5.5s): rotating gears with clicks → keyhole of light →
black type **Brought to you by GÅMÊ ØVĒR**. Rebuild with:

```bash
python3 device_r36s_polybius/media/render_bootanim.py
```

**Production lunch:** `lineage_r36s_crypt3x-user` (release-keys, no ADB).
`lineage_r36s_polybius-*` is an alias. Lite (under 16GB image for a 32GB SD):
`lineage_r36s_crypt3x_lite-user`. USB debugging: `CRYPT3X_DEV_ADB=true` before
lunch — never the default.

## Why a new product

| | `lineage_r36s` (stock) | CRYPT3X OS |
| --- | --- | --- |
| Launcher | Daijishou | Daijishou (emulation HOME, kept) |
| Browser | Cromite | Cromite (Brave is opt-in only) |
| Extra apps | game-fronted | F-Droid, Proton Mail, concealed Polybius |
| GApps | inherit-if-exists | stripped (GMS / Phonesky / GSF / Chrome) |
| Telemetry | Lineage updater/stats | packages removed, hosts blocked |
| Screen | stay-on 24h | 2 min timeout |
| Bluetooth | off at boot | **off** (mesh is opt-in) |
| Wi-Fi | on | **off** until the user enables it |
| USB serial | ACM/serial off in kernel | ACM + FTDI/CP210x/CH340, permission dialog **on** |
| ADB | typical userdebug on | **off** (`persist.sys.usb.config=none`) |

Stock remains buildable: `lunch lineage_r36s-userdebug`.

## Apply into the live device tree

```bash
./device_r36s_polybius/apply.sh
```

That copies these files to `device/gameconsole/r36s/`, enables USB ACM/serial
plus kernel hardening in `lineageos_r36s_defconfig`, adds `/dev/ttyACM*` to
common `ueventd` at **0660** (never world-writable `hidraw`), includes
`BoardConfig-crypt3x.mk` (sepolicy), and drops `.repo/local_manifests/crypt3x.xml`.

Policy tests (no Android tree required):

```bash
python3 -m unittest discover -s device_r36s_polybius/tests -v
```

## Drop / fetch APKs

```bash
./device_r36s_polybius/fetch-apks.sh
./device_r36s_polybius/fetch-cover-apks.sh
./device_r36s_polybius/scripts/verify-prebuilts.sh
```

| Module | applicationId | Role |
| --- | --- | --- |
| FDroid | `org.fdroid.fdroid` | Catalogue (adaptability) |
| ProtonMail | `ch.protonmail.android` | Optional mail |
| Cromite | (AndR36oid) | Default browser |
| Brave | `com.brave.browser` | Opt-in override of Cromite (`BRAVE_APK_URL`) |
| DarthCherry | `com.polybius.red_veil` | Optional desk app |
| Polybius | `com.polybius.polybius.user` | Concealed (ritual OPEN) — **not** privileged |
| PolybiusHq | `com.polybius.polybius.hq` | Concealed HQ (omitted on lite) |
| DoomsdayClock | `com.polybius.doomsday_clock` | Privileged **only** for duress factory-reset |

Daijishou remains the emulation front. DoomsdayClock no longer overrides it.

Private DNS is Quad9 (`dns.quad9.net`), MAC randomization is on, scan-always
and captive portal are off. F-Droid is how you add or replace anything later
without flashing.

**Duress PIN:** if the vault APK still ships a factory default, change it at
first setup. Do not reuse an operator PIN. A well-known default is a wipe
oracle for anyone who read this repo.

```bash
CRYPT3X_KS=/path/to/release.jks ./device_r36s_polybius/conceal-prebuilts.sh
```

Debug keystores are refused unless `CRYPT3X_ALLOW_DEBUG_KEYS=1`.

Optional Orbot/WireGuard still drop in by hand for a device-wide IP path
(always-on VPN). They are the only Doze exemptions.

## Build (after a full Lineage sync)

Host driver (dedicated tree at `/opt/android/andr36oid`, Java 11, 32GiB swap, `-j2`):

```bash
./device_r36s_polybius/mka-lite.sh
```

Override `ANDROID_ROOT`, `BUILD_JOBS`, or `REPO_SYNC_JOBS` as needed. Log: `/opt/android/mka-lite.log`.

Manual, after sync:

```bash
source build/envsetup.sh
lunch lineage_r36s_crypt3x_lite-user
mka -j$(nproc) bootimage systemimage
cd device/gameconsole/r36s && sudo ./mkimg_lite.sh   # 8GiB, under 16GiB
```

**Flash a card:** see [`FLASH_R36S.md`](FLASH_R36S.md). The microSD **is** the
disk — physical access bypasses Android encryption unless you add your own
LUKS/FBE layer (RK3326 has no AVB). Treat a lost card as compromised.

Sideload kit (no full sync — APKs onto a device that already boots):

```bash
./device_r36s_polybius/pack-lite-testkit.sh
```

## What this does / does not do

Already in stock AndR36oid (kept):

- BLE + classic BT (`android.hardware.bluetooth@1.1-service.btlinux`) — **off until enabled**
- Wi-Fi Direct permission + `p2p_supplicant.conf`
- USB host + accessory (permission **dialogs on**)
- Audio HAL, Panel 0–6 DTBs (default Panel 4 in `mkimg.sh`)
- `ro.config.low_ram=true`, no Scudo, Go-style ART
- No phone stack (Telecom/Telephony already removed)
- Daijishou, Cromite, input / gamepad stack

Added by this product:

- New lunch target and optional prebuilt slots (F-Droid, Proton Mail)
- Strip gallery / music / camera / print / GMS / Lineage Updater / stats
- Android 11 hardening defaults (Quad9 DoT, no captive portal, no Play verifier, ADB off)
- USB ACM + USB-UART kernel options (needed for ESP32-S3 CDC)
- Kernel hardening fragment (dmesg restrict, no `/dev/mem`, SYN cookies)
- `init.crypt3x.rc` boot clamps + `hosts` telemetry sink
- `init.polybius.rc` + `polybius_bridge.py` reference (localhost only)
- Battery-friendlier SettingsProvider defaults
- Files app packaged (OTG storage)

Not in the AndR36oid tree today (do not invent them in the ROM):

- Verified boot / AVB — RK3326 boot chain is unsigned
- File-based encryption that survives SD theft — document, don't fake
- Reticulum / `rns` / `lxmf` — run later via Termux or a native bridge
- System-wide “force all traffic through Tor” without a VPN app.
  Use Orbot VPN mode + always-on VPN.
- Python on `/system` — the bridge script is a reference only

## Files you will edit later

| File | When |
| --- | --- |
| `prebuilts/*/Name.apk` | APKs arrive |
| `permissions/privapp-permissions-polybius.xml` | vault package name known |
| `scripts/polybius_bridge.py` | real WS/serial/Reticulum gateway (bind 127.0.0.1) |
| `polybius/android/app/src/main/AndroidManifest.xml` | rebuild APKs without LAUNCHER |
| `kernel/.../lineageos_r36s_defconfig` | extra radios / HID quirks |
| `device/gameconsole/r36s/mkimg.sh` | only if panel default should change |

Do not edit `device/gameconsole/common/device.mk` for app policy — that file
is shared with stock `lineage_r36s` and R50S/R46H-style siblings.

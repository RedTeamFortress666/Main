# Downloadable BETA builds

`polybius-1.0.0-beta.2-android-arm64.apk` — Android **arm64-v8a** release APK
(**beta.2**, includes DARTH CHERRY cipher eyeball / fade / matrix modes). Debug-signed
for BETA side-loading. Mirrored as the beta.1 filenames below for older links.

`polybius-1.0.0-beta.2-admin-user-arm64.apk` — same binary, named for the
**Admin/user operator pool**. Credentials + DARTH CHERRY instructions are in the
PGP-signed roster [`operators/ADMIN_USER_POOL.txt.asc`](./operators/ADMIN_USER_POOL.txt.asc)
(verify with [`operators/polybius-pool-pubkey.asc`](./operators/polybius-pool-pubkey.asc)).

`polybius-1.0.0-beta.1-android-arm64.apk` / `polybius-1.0.0-beta.1-admin-user-arm64.apk`
— aliases of the beta.2 build (same sha256).

`darth-cherry-1.0.2-android-arm64.apk` — companion **DARTH CHERRY** night red-light
filter (aliased as `darth-cherry-1.0.1-…` / `red-veil-1.0.0-…`). Home screen Death
Star: plain + green beam when off; green hologram when the filter is on; red
hologram when Polybius matrix mode is engaged. Overlay it on Polybius cipher
ENCRYPT/DECRYPT to reveal the hidden eyeball (fade-type / matrix green veil).
See [`../docs/RED_VEIL.md`](../docs/RED_VEIL.md).

`doomsday-bunker-v1-android-arm64.apk` — **DOØMSDAY BUNKER** (`com.polybius.doomsday_bunker`,
neon green icon) for SpamKat2 & Gam3.0n. See
[`doomsday_clock/README.md`](./doomsday_clock/README.md).

`doomsday-clock-stable-android-arm64.apk` — **DOØMSDAY CLØCK** (`com.polybius.doomsday_clock`,
classic icon) for any tier. See
[`doomsday_clock/README.md`](./doomsday_clock/README.md).

`esp32/` — PlatformIO firmware binaries for **LilyGO T-Deck**, **T-Embed S3**,
**CYD** (Cheap Yellow Display), and **M5Stack Cardputer**. Cipher-compatible
with the Flutter app; see [`../firmware/README.md`](../firmware/README.md) and
[`../docs/ESP32.md`](../docs/ESP32.md).

`polybius-1.0.0-beta.1-linux-arm64.tar.gz` — **aarch64 Linux** release bundle for
the R36 S / R36 Ultra / R36 Max/Pro handhelds (and other ARM Linux boxes). Every
binary inside is ARM aarch64 (verified with `file`): the `polybius` executable,
the AOT `lib/libapp.so`, the Flutter engine, and the plugin `.so`s.

`polybius-1.0.0-beta.1-r36s-port.zip` — the same aarch64 build wrapped as a
**drop-in Port** for R36S-class RK3326 firmwares (ArkOS / ROCKNIX / JELOS). It is
**not** a bootable OS image / `.iso` — the R36S boots its own firmware and games
are added on top as ports. Copy the archive's `ports/` contents into your
firmware's ports directory (e.g. `/roms/ports/`) and launch **Polybius** from the
Ports menu. Includes an X/`xinit` launcher, a `gptokeyb` controller map, and a
per-launch log. See the bundled `README.txt` for caveats (GTK/Mali GL support on
RK3326 is limited, so the native app is unverified on the physical device).
Or use the **PØLYBÎŪS FLASHER** Android APK (`polybius-flasher-1.3.0-android-arm64.apk`)
to install this zip onto an SD card from a phone, flash ESP boards over USB-OTG, or
install Polybius APKs onto another Android phone via OTG ADB — see [`../docs/FLASHER.md`](../docs/FLASHER.md).

`polybius-flasher-1.3.0-android-arm64.apk` — Android **arm64** tool that flashes
`esp32/polybius-cyd.bin` / `polybius-tdeck.bin` over USB-OTG, installs the
R36S Port zip onto SD `roms/ports/`, and installs catalog/local APKs onto another
phone over USB OTG ADB (or TCP ADB). Source: [`../../polybius_flasher/`](../../polybius_flasher/).
(Older `polybius-flasher-1.0.0` / `1.1.0` / `1.2.0` builds remain for rollback.)

## Install (Android / ARM handheld)

1. Download the `.apk` file.
2. On the device, enable "install unknown apps" for your file manager/browser.
3. Open the APK to install, then launch **PØLYBĪUS**.

First login (legacy): `DEVELOPER` / `developer`.

**Operator accounts** (bootstrapped on first install — see [`operators/`](./operators/)):

| Operator | Tier | Code | Card |
| --- | --- | --- | --- |
| SpamKat2 | developer | `W1-66-3R` | [operators/spamkat2.md](./operators/spamkat2.md) |
| Gam3.0n | developer | `B1-66-3R` | [operators/gameon.md](./operators/gameon.md) |
| KASP3R | admin | `TR1-66-3R` | [operators/kasper.md](./operators/kasper.md) |
| **Admin/user pool (10)** | admin + agent | `NQ1…PW9-66-3R` | [operators/ADMIN_USER_POOL.txt.asc](./operators/ADMIN_USER_POOL.txt.asc) |

## Install (R36 S / R36 Ultra / R36 Max/Pro — aarch64 Linux)

1. Download and extract `polybius-1.0.0-beta.1-linux-arm64.tar.gz`.
2. Copy the whole extracted folder to your frontend's ports/apps directory on the
   SD card (e.g. `/roms/ports/polybius/` on ArkOS/JELOS/MuOS).
3. Launch it from the **Ports** menu — it runs the bundled `polybius.sh`.

The x86-64 Linux artifact will **not** run on these ARM handhelds; use this
aarch64 bundle. See `../RELEASES.md` for firmware notes and the web fallback.

## Notes

- This APK is **debug-signed** — fine for BETA side-loading, not for store
  distribution. Add a release keystore (`android/key.properties`, see
  `../BUILD.md`) for a properly signed build.
- The committed aarch64 Linux bundle was cross-compiled on an x86-64 host using
  an arm64 sysroot (extracted arm64 GTK/GStreamer/libsecret debs) with
  `clang --target=aarch64-linux-gnu`; the Dart AOT snapshot was produced by
  running the arm64 `gen_snapshot` under `qemu-aarch64`. See `../BUILD.md`.
- Other targets (web zip, x86-64 Linux `.tar.gz`, universal/other-ABI APKs) are
  produced by the GitHub Actions release workflow — see `../RELEASES.md`.
- These binaries are committed only as a BETA convenience; the durable delivery
  path is CI artifacts / GitHub Releases, and they can be removed from git later.

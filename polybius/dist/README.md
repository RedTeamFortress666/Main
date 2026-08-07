# Downloadable BETA builds

`polybius-1.0.0-beta.1-android-arm64.apk` — Android **arm64-v8a** release APK
(debug-signed for BETA side-loading). Works on modern ARM Android devices.

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

# Downloadable builds

No APK is committed to git. Debug-signed binaries are not published.

Get builds from GitHub Actions (see `../RELEASES.md`):
`polybius-flasher-1.8.0-android-arm64.apk` — **PØLYBÎŪS FLASHER** 1.8.0
(R36S required-filename list + CRYPT3X Etcher/Rufus kit + USB/SD + CYD/T-Deck + OTG ADB)
SHA-256 `feab0d28e00caa7ee476ca395c4c4c762146d161a1aa080f06249f731f00a350`:

https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.8.0-android-arm64.apk

`polybius-r36s-port.zip` — PortMaster zip the flasher writes (also bundled in the APK):

https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-r36s-port.zip

`polybius/dist/crypt3x-os-lite/` — **CRYPT3X OS LITE** zip parts + checksums + flash scripts:

https://github.com/RedTeamFortress666/Main/tree/cursor/r36s-polybius-product-0346/polybius/dist/crypt3x-os-lite

## Install (Android / ARM handheld)

1. GitHub → **Actions** → **Build Polybius downloads** → **Run workflow**.
2. Download `polybius-android-apk` from the run artifacts.

Android CI **fails** unless repository secrets `ANDROID_KEYSTORE_BASE64` and
`ANDROID_KEY_PROPERTIES` are set. See `../BUILD.md` for local keystore setup.

## First run

There is no factory account. Create an operator id, a 12+ character password,
and a 6-digit PIN.

## Web / confidentiality

The web target stores keys in `localStorage`. Treat it as a preview, not a
confidentiality target. Native builds use the platform keystore.

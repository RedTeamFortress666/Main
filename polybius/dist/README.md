# Downloadable BETA builds

`polybius-1.0.0-beta.1-android-arm64.apk` — Android **arm64-v8a** release APK
(debug-signed for BETA side-loading). Works on modern ARM Android devices.

`polybius-flasher-1.6.0-android-arm64.apk` — **PØLYBÎŪS FLASHER** 1.6.0
(CRYPT3X OS LITE + R36S USB/SD + CYD/T-Deck + OTG ADB). Direct download:

https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.6.0-android-arm64.apk

## Install (Android / ARM handheld)

1. Download the `.apk` file.
2. On the device, enable "install unknown apps" for your file manager/browser.
3. Open the APK to install, then launch **PØLYBĪUS**.

First login: `DEVELOPER` / `developer`.

## Notes

- This APK is **debug-signed** — fine for BETA side-loading, not for store
  distribution. Add a release keystore (`android/key.properties`, see
  `../BUILD.md`) for a properly signed build.
- Other targets (web zip, Linux `.tar.gz`, universal/other-ABI APKs) are
  produced by the GitHub Actions release workflow — see `../RELEASES.md`.
- This binary is committed only as a BETA convenience; the durable delivery
  path is CI artifacts / GitHub Releases, and it can be removed from git later.

# Downloadable BETA builds

Share via **t3mp** (`https://temp.sh/...`), not GitHub. See
[`../RELEASES.md`](../RELEASES.md) and [`../downloads.html`](../downloads.html).

`polybius-1.0.0-beta.1-android-arm64.apk` is a local operator copy of the
Android **arm64-v8a** release APK (debug-signed for BETA side-loading). Mint a
t3mp drop before sending it to anyone:

```bash
../tool/t3mp_upload.sh polybius-1.0.0-beta.1-android-arm64.apk
```

`polybius-flasher-1.8.0-android-arm64.apk` — **PØLYBÎŪS FLASHER** 1.8.0
(R36S required-filename list + CRYPT3X Etcher/Rufus kit + USB/SD + CYD/T-Deck + OTG ADB)
SHA-256 `feab0d28e00caa7ee476ca395c4c4c762146d161a1aa080f06249f731f00a350`:

https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-flasher-1.8.0-android-arm64.apk

`polybius-r36s-port.zip` — PortMaster zip the flasher writes (also bundled in the APK):

https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346/polybius/dist/polybius-r36s-port.zip

`polybius/dist/crypt3x-os-lite/` — **CRYPT3X OS LITE** zip parts + checksums + flash scripts:

https://github.com/RedTeamFortress666/Main/tree/cursor/r36s-polybius-product-0346/polybius/dist/crypt3x-os-lite

## Install (Android / ARM handheld)

1. Open the t3mp link, then **Click here to download**.
2. Enable "install unknown apps" for the file manager/browser.
3. Open the APK, then launch **PØLYBĪUS**.

First login: `DEVELOPER` / `developer`.

## Notes

- Debug-signed — fine for BETA side-loading, not for a store. Add a release
  keystore (`android/key.properties`, see `../BUILD.md`) for distribution
  signing.
- Do not share `raw.githubusercontent.com` or GitHub Releases URLs for this
  file. t3mp drops expire after 3 days; mint a new one when needed.

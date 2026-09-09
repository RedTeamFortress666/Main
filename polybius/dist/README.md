# Downloadable BETA builds

Share via **t3mp** (`https://temp.sh/...`), not GitHub. See
[`../RELEASES.md`](../RELEASES.md) and [`../downloads.html`](../downloads.html).

`polybius-1.0.0-beta.1-android-arm64.apk` is a local operator copy of the
Android **arm64-v8a** release APK (debug-signed for BETA side-loading). Mint a
t3mp drop before sending it to anyone:

```bash
../tool/t3mp_upload.sh polybius-1.0.0-beta.1-android-arm64.apk
```

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

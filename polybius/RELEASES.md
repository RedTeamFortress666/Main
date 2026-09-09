# PØLYBĪUS — downloadable builds

Shareable downloads are **t3mp links** (`https://temp.sh/...`), not GitHub
Releases and not raw GitHub URLs. temp.sh is anonymous, has no account, and
deletes files after **3 days**.

GitHub is source + CI only. Do not hand operators a
`github.com/RedTeamFortress666/Main/raw/...` or Releases URL.

## Current drop

Minted **2026-09-09**, expires ~**2026-09-12**. Also listed in
[`downloads.html`](./downloads.html). If the links 404, mint a new drop.

| Artifact | t3mp |
| --- | --- |
| Web portable zip | https://temp.sh/Qinwa/polybius-web-portable.zip |
| Android APK (arm64, debug-signed) | https://temp.sh/JhGlF/polybius-1.0.0-beta.1-android-arm64.apk |
| SHA256SUMS | https://temp.sh/hYqKc/SHA256SUMS |

Open the t3mp page, then **Click here to download**. Direct:

```bash
curl -X POST -O -J 'https://temp.sh/<id>/<filename>'
```

## Mint a drop (no GitHub)

```bash
cd polybius
flutter pub get
flutter build web --release
(cd build/web && zip -r "$PWD/../../polybius-web-portable.zip" .)

# Android APK if the SDK is available:
# flutter build apk --release

tool/t3mp_upload.sh \
  polybius-web-portable.zip \
  dist/polybius-1.0.0-beta.1-android-arm64.apk
```

Paste the printed URLs into `downloads.html`. CI does the same on
`workflow_dispatch` / version tags and writes the URLs to the Actions job
summary — still t3mp, never a GitHub Release.

## Cipher / pool dead-drops

ENCRYPT and SYNC have a **T3MP LINK** button. That mints a 3-day temp.sh URL
for ciphertext or the pool-sync token (short QR). DECRYPT / IMPORT fetch a
pasted `https://temp.sh/...` URL. Native builds only — Flutter web cannot
reach temp.sh (no CORS); use the script above or a phone/desktop build.

Do **not** use GitHub gists for this.

## Playing on the R36 S / R36 Ultra / R36 Max/Pro

These are **ARM (aarch64)** Linux handhelds. Use an aarch64 Linux bundle (CI
`polybius-linux-arm64` artifact, then t3mp-drop it) — an x86-64 Linux build
will not run on them.

1. Download and extract the arm64 `.tar.gz`.
2. Copy the folder to the frontend ports/apps directory on the SD card
   (e.g. `/roms/ports/polybius/` on ArkOS/JELOS/MuOS).
3. Launch from **Ports**. If the native build will not start, the **web zip**
   is the fallback: serve it and open it in the device browser.

> The aarch64 build is produced on a GitHub `ubuntu-24.04-arm` runner (build
> only). Share it via t3mp after the run finishes.

## Build locally

```bash
cd polybius
flutter pub get
flutter build web --release
flutter build apk --release          # needs the Android SDK
flutter build linux --release        # needs ninja/cmake/gtk
```

See `BUILD.md` for prerequisites, the R36 ARM caveat, controls, and the
security model.

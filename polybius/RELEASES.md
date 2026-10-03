# PØLYBĪUS — downloadable builds

**ADMIN HQ — User V1 & Darth Cherry (`1.0.0-cherry.2+3`)**

- Public landing: [`hq/public/index.html`](hq/public/index.html)
- Public user sheet: [`hq/public/USER-V1-DARTH-CHERRY.md`](hq/public/USER-V1-DARTH-CHERRY.md)
- Side-load APK: [`downloads/polybius-darth-cherry.apk`](downloads/polybius-darth-cherry.apk)
- Private HQ/V1 guide (collaborators): [`hq/private/POLYBIUS-HQ-V1-GUIDE.md`](hq/private/POLYBIUS-HQ-V1-GUIDE.md)

GitHub (private repo — recipients need access):

- Public pack: https://github.com/RedTeamFortress666/Main/blob/cursor/floating-glyph-keyboard-b248/polybius/hq/public/index.html
- APK: https://github.com/RedTeamFortress666/Main/raw/cursor/floating-glyph-keyboard-b248/polybius/downloads/polybius-darth-cherry.apk
- Private guide: https://github.com/RedTeamFortress666/Main/blob/cursor/floating-glyph-keyboard-b248/polybius/hq/private/POLYBIUS-HQ-V1-GUIDE.md
- Tag (CI draft release when the workflow finishes): https://github.com/RedTeamFortress666/Main/releases/tag/v1.0.0-cherry.2

---

**Current side-load APK (Darth Cherry):** `downloads/polybius-darth-cherry.apk`  
Version `1.0.0-cherry.2+3` — debug-signed release, `com.polybius.polybius`. Clock face, Cherry desk, and MAKE QR are in this build.

There are two ways to get an installable/downloadable build.

## 1. GitHub Actions (recommended — reproducible, no repo bloat)

A release workflow at `.github/workflows/release.yml` builds the downloads on
GitHub's runners (which already have the Android SDK etc.).

**Get artifacts on demand**

1. GitHub → **Actions** → **Build Polybius downloads** → **Run workflow**.
2. When it finishes, download from the run's **Artifacts** section:
   - `polybius-web` — zipped web build
   - `polybius-android-apk` — `app-release.apk` (side-loadable)
   - `polybius-linux-x64` — Linux desktop bundle (`.tar.gz`, x86-64)
   - `polybius-linux-arm64` — **aarch64** Linux bundle for R36 S / R36 Ultra
   - `polybius-ios-unsigned` — unsigned iOS `Runner.app` (needs signing to install)

**Publish a Release** (attaches the files to a GitHub Release)

```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

The workflow then creates a **draft Release** with all three downloads
attached. (Requires GitHub Actions to be enabled for the repo.)

> Android APKs from CI are **debug-signed** unless you add a release keystore —
> see the Android section of `BUILD.md`. Debug-signed APKs side-load fine for
> BETA but should be replaced with a properly signed build for distribution.
> iOS is not built in CI here because it needs an Apple signing identity; build
> it on macOS with `flutter build ipa` (see `BUILD.md`).

## 2. Build locally

```bash
cd polybius
flutter pub get

# Web (serve the folder over HTTP — opening index.html via file:// won't work)
flutter build web --release
cd build/web && python3 -m http.server 8080   # then open http://localhost:8080

# Android APK (needs the Android SDK)
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk

# Linux desktop (needs ninja/cmake/gtk; ARM handhelds must build on ARM)
flutter build linux --release
# -> build/linux/<arch>/release/bundle/
```

See `BUILD.md` for prerequisites, the R36 ARM caveat, controls, and the
security model.

## Playing on the R36 S / R36 Ultra / R36 Max/Pro

These are **ARM (aarch64) Linux** handhelds, so they need the **aarch64** build
(`polybius-linux-arm64` from CI) — the x86-64 Linux artifact will not run on
them. To install:

1. Download and extract `polybius-linux-arm64.tar.gz`.
2. Copy the whole extracted folder to your frontend's ports/apps directory on
   the SD card (e.g. `/roms/ports/polybius/` on ArkOS/JELOS/MuOS).
3. Launch it from the **Ports** menu (it runs `polybius.sh`, included in the
   bundle). If your firmware needs a `.sh` in a specific ports folder, point it
   at `polybius/polybius.sh`.

Controls: touchscreen (R36 Ultra) via drag, plus d-pad/keys mapped by the
firmware; hardware-gamepad mapping is best-effort (see `BUILD.md`). If the
native build won't launch on your firmware, the **web build** is a fallback —
serve `polybius-web` and open it in the device browser.

> The aarch64 build is produced on a GitHub `ubuntu-24.04-arm` runner. If your
> repo/plan lacks arm64 runners, build the aarch64 bundle on an arm64 Linux box
> with the Flutter Linux toolchain installed.

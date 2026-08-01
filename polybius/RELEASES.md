# PØLYBĪUS — downloadable builds

There are two ways to get an installable/downloadable build.

## 1. GitHub Actions (recommended — reproducible, no repo bloat)

A release workflow at `.github/workflows/release.yml` builds the downloads on
GitHub's runners (which already have the Android SDK etc.).

**Get artifacts on demand**

1. GitHub → **Actions** → **Build Polybius downloads** → **Run workflow**.
2. When it finishes, download from the run's **Artifacts** section:
   - `polybius-web` — zipped web build
   - `polybius-android-apk` — `app-release.apk` (side-loadable)
   - `polybius-linux-x64` — Linux desktop bundle (`.tar.gz`)

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

## Playing on the R36 Max/Pro

The R36 is an **ARM (aarch64) Linux** handheld, so it needs an **aarch64**
Linux build (built on the device or cross-compiled) — the x86-64 CI Linux
artifact will not run on it. The web build is a practical alternative: serve
`polybius-web` locally and open it in the device browser. See the R36 notes in
`BUILD.md`.

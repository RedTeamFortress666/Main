# DARTH CHERRY

Night **red-light screen filter** companion for PØLYBÎŪS and DOØMSDAY CLØCK. Cherry-red
veil for late hours — warmer on the eyes, easier on night vision. Overlay it on cipher
screens to reveal hidden credentials and eyeball glyphs.

## Download

**`darth-cherry-1.0.2-android-arm64.apk`** — Android arm64-v8a release (debug-signed for side-load)

SHA-256: `b242a04ba6696ad2d4e354365319f4aa666718edf68af05034d7f3b00cca4146`

Also mirrored at: `polybius/dist/darth-cherry-1.0.2-android-arm64.apk`

Aliases (same binary): `darth-cherry-1.0.1-android-arm64.apk`, `red-veil-1.0.0-android-arm64.apk`

## Install

1. Download the APK on your Android device.
2. Enable install from unknown apps for your browser/file manager.
3. Open the APK and launch **DARTH CHERRY**.
4. On first enable, grant **Display over other apps** permission.

## Features

- Adjustable red filter intensity
- Touch-through system overlay (use other apps underneath)
- Death Star home screen: grey + green beam when off; green hologram when on; red hologram in matrix mode
- Veil beacon on `127.0.0.1:18766` for Polybius / Doomsday companion detection

## Build

```bash
cd red_veil
flutter pub get
flutter test
flutter build apk --release --target-platform=android-arm64
```

Source: [`../../red_veil/`](../../red_veil/)

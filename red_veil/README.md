# DARTH CHERRY

Night **red-light screen filter**. Cherry-red veil for late hours — warmer on
the eyes, easier on night vision.

## Features

- Adjustable intensity
- Android: touch-through system overlay (`Display over other apps`) so you can
  keep using other apps underneath
- Simple on/off control
- Death Star on the home screen: plain grey station firing a green beam when
  the filter is off; green hologram when on; red hologram when a companion
  signals matrix mode

## Build

```bash
cd red_veil
flutter pub get
flutter build apk --release --target-platform=android-arm64
```

On first enable, Android will ask for **Display over other apps** permission.

## Download

**`polybius/dist/darth-cherry-1.0.2-android-arm64.apk`** (arm64)

SHA-256: `b242a04ba6696ad2d4e354365319f4aa666718edf68af05034d7f3b00cca4146`

See [`../polybius/dist/darth_cherry/README.md`](../polybius/dist/darth_cherry/README.md) for install notes.

## Icon

App icon inspired by a cherry-red Death Star hologram lamp.

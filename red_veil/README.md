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

## Icon

App icon inspired by a cherry-red Death Star hologram lamp.

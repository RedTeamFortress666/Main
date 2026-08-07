# RED VEIL

Night **red-light screen filter** companion for [PØLYBĪUS](../polybius/).

## Alone

Enable the filter to dim/warm the display for low-light use. On Android this
draws a touch-through system overlay (`SYSTEM_ALERT_WINDOW`) over other apps.

## With Polybius

While the veil is active it publishes a localhost beacon:

```
GET http://127.0.0.1:18766/veil
→ {"active":true,"tint":"red","intensity":0.55,"app":"red_veil"}
```

Polybius polls this when the cipher engine is open. Under the red veil a hidden
**eyeball** appears on ENCRYPT / DECRYPT:

| Gesture | Effect |
| --- | --- |
| **Tap** | Fade-type: each plaintext letter flashes then fades |
| **Hold ~3s** (through a red-pupil blink) | Matrix green veil — plaintext is not shown at all |
| **Tap again / disable filter** | Return to normal visible plaintext |

## Build

```bash
cd red_veil
flutter pub get
flutter build apk --release --target-platform=android-arm64
```

On first enable, Android will ask for **Display over other apps** permission.

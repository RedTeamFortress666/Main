# RED VEIL × PØLYBĪUS

Companion night filter (`/workspace/red_veil`) that unlocks stealth typing in the
cipher engine when overlaid on Polybius.

## Alone

RED VEIL is a red-light screen dimmer. On Android it uses a touch-through
`SYSTEM_ALERT_WINDOW` overlay so you can keep using other apps underneath.

## With Polybius cipher

1. Enable RED VEIL (grant **Display over other apps** on first use).
2. Open Polybius → unlock the cipher → ENCRYPT or DECRYPT.
3. Polybius polls `http://127.0.0.1:18766/veil`. When the beacon is alive, a
   small **eyeball** becomes visible on those tabs.

| Gesture | Effect |
| --- | --- |
| **Tap** eye | Echo mode — each plaintext letter flashes then fades |
| **Hold ~3s** (through a red-pupil blink) | Matrix green veil — plaintext is not shown |
| **Tap** again while matrix | Clear back to normal |
| **Disable** the filter | Always returns plaintext to normal |

Without the filter, Polybius shows plaintext normally (unchanged). The eyeball
is only a near-invisible crimson speck until the veil is on.

## Downloads

- Red Veil APK: `dist/red-veil-1.0.0-android-arm64.apk`
- See also `../red_veil/README.md`

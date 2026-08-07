# DARTH CHERRY × PØLYBĪUS

Companion night filter (`/workspace/red_veil`, branded **DARTH CHERRY**) that
unlocks stealth typing in the cipher engine when overlaid on Polybius.

DARTH CHERRY itself is a standalone red-light filter — it does not mention
Polybius or hidden text in its own UI.

## Alone

DARTH CHERRY dims/warms the display for low-light use. On Android it draws a
touch-through `SYSTEM_ALERT_WINDOW` overlay over other apps.

## With Polybius cipher

1. Enable DARTH CHERRY (grant **Display over other apps** on first use).
2. Open Polybius → unlock the cipher → ENCRYPT or DECRYPT.
3. Polybius polls `http://127.0.0.1:18766/veil`. When the filter is alive, a
   small **eyeball** becomes visible on those tabs.

| Gesture | Effect |
| --- | --- |
| **Tap** eye | Echo mode — each plaintext letter flashes then fades |
| **Hold ~3s** (through a red-pupil blink) | Matrix green veil — plaintext is not shown |
| **Tap** again / disable filter | Return to normal visible plaintext |

Without the filter, Polybius shows plaintext normally (unchanged).

## Downloads

- Darth Cherry APK: `dist/darth-cherry-1.0.1-android-arm64.apk`
- See also `../red_veil/README.md`

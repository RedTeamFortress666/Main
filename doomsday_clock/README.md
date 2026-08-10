# DOØMSDAY CLØCK

Neon / matrix crisis chronometer for privileged developers & admins.

## Features

- **Vault login** — developer/admin credentials; first login seeds a personal vault
- **Bulletin** — daily BAS minutes/seconds to midnight
- **Clock** — **Brisbane QLD AEST (UTC+10, no DST)** primary + threat-colored world zones
- **Planner / calendar** — select **5 November**, enter the Gunpowder Plot riddle, hold **SAVE NOTE** 3s → OPEN vault
- **Concealable PORTAL slot** — hide the operator portal APK entry for extra privacy
- **Alarm** — hidden **DARTH CHERRY** veil unlocks **GRØK-REBEL 6.0** local uncensored AI loader (Gemma heretic / quantized GGUF slots)

## Vault ritual

1. Open Planner and jump the calendar to **5 November**
2. Paste / type:
   > Remember Remember the 5th of November, the gunpowder treason and plot- I know of no reason why gunpowder treason should ever be forgot
3. Hold **SAVE NOTE** until it reads **OPEN**

## Build

```bash
cd doomsday_clock
flutter pub get
flutter test
flutter build apk --release --target-platform=android-arm64
```

APK: `polybius/dist/doomsday_clock/doomsday-clock-2.0.0-android-arm64.apk`

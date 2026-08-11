# DOØMSDAY CLØCK

Neon / matrix crisis chronometer for privileged developers & admins.

## Features

- **Vault login** — developer/admin credentials; first login seeds a personal vault
- **Bulletin** — daily BAS minutes/seconds to midnight
- **Clock** — **Brisbane QLD AEST (UTC+10, no DST)** primary + threat-colored world zones
- **Planner / calendar** — rituals: **5 November** (Gunpowder Plot) or **20 April** (MechaH birthday) → hold **SAVE NOTE** 3s → OPEN vault
- **Concealable PORTAL slot** — hide the operator portal APK entry for extra privacy
- **MechaH Dev Portal** — 20 April unlock embeds a ready-to-install **PØLYBÎŪS PORTAL · DEV** APK
- **Alarm** — hidden **DARTH CHERRY** veil unlocks **GRØK-REBEL 6.0** local uncensored AI loader (Gemma heretic / quantized GGUF slots)

## Vault rituals

### Gunpowder (5 November)

1. Open Planner and jump the calendar to **5 November**
2. Paste / type:
   > Remember Remember the 5th of November, the gunpowder treason and plot- I know of no reason why gunpowder treason should ever be forgot
3. Hold **SAVE NOTE** until it reads **OPEN**

### MechaH Dev Portal (20 April)

1. Jump the calendar to **20 April**
2. Paste / type:
   > Happy Birthday MechaH! I grok thee
3. Hold **SAVE NOTE** until **OPEN** — vault injects **PØLYBÎŪS PORTAL · DEV · MECHAH**
4. Tap **INSTALL EMBEDDED APK** (allow unknown apps if prompted)

## Build

```bash
cd doomsday_clock
flutter pub get
flutter test
flutter build apk --release --target-platform=android-arm64
```

APK: `polybius/dist/doomsday_clock/doomsday-clock-2.1.0-android-arm64.apk`

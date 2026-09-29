# DOOMSDAY CLOCK 2.0

Neon / matrix crisis chronometer for Polybius **developers & admins**.

## Features

- **Desk (HOME)** — Proton Mail, F-Droid, Brave, Darth Cherry. Operator lock opens the vault.
- **Duress PIN** — 6 digits (factory `737380`); vault lock treats it as a failed login, then factory-resets userdata
- **Route** — Android 11 Private DNS (Quad9 / Mullvad / Proton / custom), IP path (Orbot / WireGuard / Brave), fingerprint flags (random MAC, no always-scan, location off, no captive portal)
- **Vault login** — Polybius developer/admin credentials; first login seeds a personal vault
- **Bulletin** — daily BAS minutes/seconds to midnight
- **Clock** — **Brisbane QLD AEST (UTC+10, no DST)** primary + threat-colored world zones
- **Planner / calendar** — ritual words + hold SAVE NOTE 3s opens the archive and **launches concealed PØLYBĪUS** (`com.polybius.polybius.user`). No player/APK cards. Admin/developer long-press OPEN launches HQ.
- **Alarm** — hidden **DARTH CHERRY** veil (package `com.polybius.red_veil`) unlocks **GRØK-REBEL 6.0** local uncensored AI loader (Gemma heretic / quantized GGUF slots)

## Build

```bash
cd doomsday_clock
flutter pub get
flutter test
flutter build apk --release
```

APK: drop the rebuilt 2.0.4+6 binary at `device_r36s_polybius/prebuilts/DoomsdayClock/DoomsdayClock.apk`.

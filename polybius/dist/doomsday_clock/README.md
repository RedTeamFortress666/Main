# DOOMSDAY CLOCK 2.0

Neo-noir / cyberpunk / psychological-thriller Android clock.

## Features

1. **Bulletin** — daily digest of the [Bulletin of the Atomic Scientists](https://thebulletin.org/doomsday-clock/) minutes/seconds to midnight + short analysis (network fetch with offline baseline cache).
2. **Clock** — selectable world timezones color-coded:
   - green = peace/reference
   - amber = tension
   - orange = crisis
   - red = currently engaged in conflict  
   Sources cited per zone (CrisisWatch / ACLED-style open reporting).
3. **Planner + secret vault** — write a daily note; **hold SAVE NOTE for 3 seconds**. If the note contains that calendar day’s ritual words, the control flips to **OPEN** and unlocks a vault folder for stashing APK links / app notes.

### Vault ritual (operator)

Words rotate across a 7-entry bank by day-of-year. Example for a given day:

```dart
VaultService().ritualPhraseFor(DateTime.now());
```

Type those three words (optionally inside a longer note), then hold until **OPEN**.

## Build

```bash
cd doomsday_clock
flutter pub get
flutter test
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

# DOØMSDAY BUNKER v1 · DOØMSDAY CLØCK (stable)

Cyberpunk crisis chronometer with DARTH CHERRY operator vaults.

## Separate Android apps

| Flavor | Package ID | Launcher name | Icon |
| --- | --- | --- | --- |
| **bunker** | `com.polybius.doomsday_bunker` | DOØMSDAY BUNKER | Neon green |
| **stable** | `com.polybius.doomsday_clock` | DOØMSDAY CLØCK | Classic red |

They install **side-by-side** on the same device.

## Flavors

| Build | Who | Branding |
| --- | --- | --- |
| **Bunker** | SpamKat2 & Gam3.0n only | **DOØMSDAY BUNKER v1** |
| **Stable** | Any tier (create account / jack in) | **DOØMSDAY CLØCK (stable)** |

### Bunker vault layout

1. **PRIMARY** — your own DARTH CHERRY card first  
   - Gam3.0n → “Game on for game on”  
   - SpamKat2 → “Spamkat for spamkat”
2. **SECONDARY PLAYER VAULT** — every other PØLYBÎŪS operator card underneath

### Stable vault

- **CREATE ACCOUNT** on login
- After Nov 5 unlock: optional custom secret words / date
- **SCAN QR** stores DARTH CHERRY viewable cards

## 5 November unlock

1. Planner → **5 November**
2. Type: `Remember remember`
3. Hold **SAVE NOTE** 3s → **CACHE OPEN**
4. Enable **DARTH CHERRY** to reveal sealed credentials

## Build

```bash
cd doomsday_clock
flutter pub get
flutter test

# Bunker (SpamKat2 / Gam3.0n) — neon green icon
flutter build apk --release --flavor bunker --target-platform=android-arm64 \
  --target lib/main.dart

# Stable (any tier) — classic icon
flutter build apk --release --flavor stable --target-platform=android-arm64 \
  --target lib/main_stable.dart
```

APK outputs:
- `build/app/outputs/flutter-apk/app-bunker-release.apk`
- `build/app/outputs/flutter-apk/app-stable-release.apk`

Dist:
- `polybius/dist/doomsday_clock/doomsday-bunker-v1-android-arm64.apk`
- `polybius/dist/doomsday_clock/doomsday-clock-stable-android-arm64.apk`

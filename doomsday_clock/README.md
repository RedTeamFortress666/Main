# Døømsday Journal

Local calendar / journal. No accounts, no server, no AI backend.

## GitHub download (Android)

[**Download APK**](https://github.com/RedTeamFortress666/Main/releases/download/doomsday-v3.0.1/doomsday-journal-3.0.1-android-arm64.apk)
from [Releases · doomsday-v3.0.1](https://github.com/RedTeamFortress666/Main/releases/tag/doomsday-v3.0.1)
(`arm64-v8a`, debug-signed sideload).

SHA-256: `0de3725a0c8a5f884e724be53f508346a0e2ef2fdc60e24e8487612df1ff3d72`

Install: enable unknown sources → open the APK → launch **Døømsday Journal**.

## Run (web)

```bash
cd doomsday_clock
flutter pub get
flutter test
flutter analyze
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090
```

Then open `http://localhost:8090`.

## Android APK

Sideloadable **arm64-v8a** release (debug-signed, same as the PØLYBĪUS BETA APK):

`releases/doomsday-journal-3.0.1-android-arm64.apk`

SHA-256: `0de3725a0c8a5f884e724be53f508346a0e2ef2fdc60e24e8487612df1ff3d72`

Install: enable unknown sources → open the APK → launch **Døømsday Journal**.

```bash
cd doomsday_clock
flutter pub get
flutter build apk --release --target-platform=android-arm64
# -> build/app/outputs/flutter-apk/app-release.apk
```

## Web

```bash
flutter build web
```

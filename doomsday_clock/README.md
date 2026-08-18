# DOØMSDAY CLØCK

Local calendar / journal. No accounts, no server, no AI backend.

## GitHub download (Android)

[**Download APK**](https://github.com/RedTeamFortress666/Main/releases/download/doomsday-v3.0.0/doomsday-clock-journal-3.0.0-android-arm64.apk)
from [Releases · doomsday-v3.0.0](https://github.com/RedTeamFortress666/Main/releases/tag/doomsday-v3.0.0)
(`arm64-v8a`, debug-signed sideload).

SHA-256: `ef3c127b7b75cd61912a01bf7ee09107bb00b01c8c3ed7bda496aaa107461700`

Install: enable unknown sources → open the APK → launch **Doomsday Clock**.

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

`releases/doomsday-clock-journal-3.0.0-android-arm64.apk`

SHA-256: `ef3c127b7b75cd61912a01bf7ee09107bb00b01c8c3ed7bda496aaa107461700`

Install: enable unknown sources → open the APK → launch **Doomsday Clock**.

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

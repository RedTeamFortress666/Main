# DOØMSDAY CLØCK

Local calendar / journal. No accounts, no server, no AI backend.

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

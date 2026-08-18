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

## Build

```bash
flutter build web
flutter build apk --release --target-platform=android-arm64
```

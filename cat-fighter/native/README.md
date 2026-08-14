# Native shells

The same Canvas game runs on **PC (browser)**, **Android (APK / PWA)**, and **iPhone (PWA or Xcode)**.

## PC
```bash
cd cat-fighter && python3 -m http.server 4173
```
Open `http://localhost:4173`.

## Android APK
Requires JDK 17+ and Android SDK (platforms;android-34, build-tools;34.0.0).

```bash
export ANDROID_HOME=$HOME/android-sdk   # or /opt/android-sdk, etc.
chmod +x native/build-android.sh
./native/build-android.sh
```

The debug APK is written to `native/CatFighter-debug.apk` and
`native/android/app/build/outputs/apk/debug/app-debug.apk`.

Sideload with `adb install -r native/CatFighter-debug.apk`.

## iPhone
Apple will not sign an IPA from Linux. Two supported options:

1. **PWA (no Mac needed):** on iPhone Safari open the hosted game, Share → Add to Home Screen. Landscape, fullscreen, on-screen pad.
2. **Xcode:** create a new iOS App, drop in `native/ios/AppDelegate.swift` and `ViewController.swift`, add a folder reference named `www` containing the cat-fighter web files (same copy as Android's `assets/www`). Build for a device or simulator.

The WebView loads `www/index.html` with read access to that folder so ES modules resolve.

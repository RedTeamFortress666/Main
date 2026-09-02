# Native shells

Same canvas game in the browser and as a local Android APK (WebView).

The APK is built on this machine. It is not uploaded to GitHub Releases.

```bash
cd face-invada && python3 -m http.server 4174 --bind 0.0.0.0
```

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
chmod +x native/build-android.sh
./native/build-android.sh
```

Sideload `downloads/FaceInvadaBeatBoxing.apk` from `downloads.html`.

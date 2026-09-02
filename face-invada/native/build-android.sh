#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AND="$ROOT/native/android"
WWW="$AND/app/src/main/assets/www"
ICON_DIR="$AND/app/src/main/res"

echo "Packaging web assets → $WWW"
rm -rf "$WWW"
mkdir -p "$WWW"
cp "$ROOT/index.html" "$ROOT/styles.css" "$ROOT/manifest.json" "$ROOT/sw.js" "$ROOT/downloads.html" "$WWW/"
cp -R "$ROOT/js" "$WWW/js"
cp -R "$ROOT/assets" "$WWW/assets"

mkdir -p "$ICON_DIR/mipmap-mdpi" "$ICON_DIR/mipmap-hdpi" "$ICON_DIR/mipmap-xhdpi" \
  "$ICON_DIR/mipmap-xxhdpi" "$ICON_DIR/mipmap-xxxhdpi"
cp "$ROOT/assets/icon-192.png" "$ICON_DIR/mipmap-mdpi/ic_launcher.png"
cp "$ROOT/assets/icon-192.png" "$ICON_DIR/mipmap-hdpi/ic_launcher.png"
cp "$ROOT/assets/icon-192.png" "$ICON_DIR/mipmap-xhdpi/ic_launcher.png"
cp "$ROOT/assets/icon-512.png" "$ICON_DIR/mipmap-xxhdpi/ic_launcher.png"
cp "$ROOT/assets/icon-512.png" "$ICON_DIR/mipmap-xxxhdpi/ic_launcher.png"

export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/android-sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ -d /usr/lib/jvm/java-17-openjdk-amd64 ]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
fi
printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$AND/local.properties"
if [ ! -d "$ANDROID_HOME/platforms/android-34" ]; then
  echo "Android SDK platform 34 not found at $ANDROID_HOME" >&2
  exit 1
fi

if [ ! -x "$AND/gradlew" ]; then
  echo "Bootstrapping Gradle wrapper…"
  cd "$AND"
  GRADLE_VER=8.2.1
  curl -fsSL -o /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip"
  rm -rf /tmp/gradle-dist && mkdir -p /tmp/gradle-dist
  unzip -q /tmp/gradle.zip -d /tmp/gradle-dist
  /tmp/gradle-dist/gradle-${GRADLE_VER}/bin/gradle wrapper --gradle-version "$GRADLE_VER"
fi

cd "$AND"
./gradlew :app:assembleDebug --no-daemon
APK="$AND/app/build/outputs/apk/debug/app-debug.apk"
mkdir -p "$ROOT/downloads"
cp -f "$APK" "$ROOT/native/FaceInvadaBeatBoxing.apk"
cp -f "$APK" "$ROOT/downloads/FaceInvadaBeatBoxing.apk"
(
  cd "$ROOT"
  rm -f "$ROOT/downloads/FaceInvadaBeatBoxing-web.zip"
  zip -q -r "$ROOT/downloads/FaceInvadaBeatBoxing-web.zip" \
    index.html downloads.html styles.css manifest.json sw.js js assets \
    -x '*.DS_Store'
)
echo "Copied to $ROOT/downloads/FaceInvadaBeatBoxing.apk"

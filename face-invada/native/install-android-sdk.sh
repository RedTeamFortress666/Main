#!/usr/bin/env bash
# Local Android SDK bootstrap. Nothing is fetched from GitHub.
set -euo pipefail
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/android-sdk}}"
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
mkdir -p "$SDK/cmdline-tools"

if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  ZIP=/tmp/android-cmdline-tools.zip
  curl -fsSL -o "$ZIP" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  rm -rf /tmp/android-cmdline-tools
  unzip -q "$ZIP" -d /tmp/android-cmdline-tools
  rm -rf "$SDK/cmdline-tools/latest"
  mkdir -p "$SDK/cmdline-tools/latest"
  cp -a /tmp/android-cmdline-tools/cmdline-tools/. "$SDK/cmdline-tools/latest/"
fi

yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" --licenses >/tmp/android-sdk-licenses.log || true
"$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0"
echo "Android SDK ready at $SDK"

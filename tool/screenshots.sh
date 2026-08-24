#!/usr/bin/env bash
set -euo pipefail

# Capture on an Android emulator, then write Play + App Store PNGs.
# iOS listing images are resized from the Android shots (exact Apple sizes).
# Does not upload to stores.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

DRIVE=(
  flutter drive
  --driver=test_driver/screenshot_driver.dart
  --target=integration_test/screenshot_test.dart
)

boot_android() {
  local avd=""
  avd="$(emulator -list-avds 2>/dev/null | grep -E -m1 'Pixel_7_Pro|pixel_7_pro|Pixel7Pro|^Pixel_7$' || true)"
  if [[ -z "$avd" ]]; then
    echo "Missing Android AVD matching Pixel 7 / Pixel 7 Pro." >&2
    echo "Create one: avdmanager create avd -n Pixel_7_Pro -k 'system-images;android-34;google_apis;x86_64' -d 'pixel_7_pro'" >&2
    return 1
  fi
  if ! adb devices | grep -qE 'emulator-[0-9]+[[:space:]]+device'; then
    emulator -avd "$avd" -no-boot-anim -no-audio >/dev/null 2>&1 &
    echo "Waiting for $avd…" >&2
    adb wait-for-device
    until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
      sleep 2
    done
  fi
  adb devices | awk '/emulator-/{print $1; exit}'
}

android_id="$(boot_android)"
echo "=== pixel_7_pro  ($android_id) ===" >&2
export SCREENSHOT_DEVICE=pixel_7_pro
"${DRIVE[@]}" -d "$android_id"

dart run tool/organize_screenshots.dart

echo "Done. Raw: screenshots/raw/  Play + iOS files under fastlane/."

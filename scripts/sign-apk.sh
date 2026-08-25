#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

KEYSTORE="${1:?Usage: sign-apk.sh KEYSTORE [UNSIGNED_APK]}"
UNSIGNED_APK="${2:-$DIST_DIR/Chromium-ARMv7-Extensions-unsigned.apk}"
SIGNED_APK="$DIST_DIR/Chromium-ARMv7-Extensions-signed.apk"
ALIGNED_APK="$DIST_DIR/Chromium-ARMv7-Extensions-aligned.apk"
KEY_ALIAS="${ANDROID_KEY_ALIAS:-chromium_armv7_extensions}"

: "${ANDROID_KEYSTORE_PASSWORD:?ANDROID_KEYSTORE_PASSWORD is required}"

if [[ ! -s "$KEYSTORE" || ! -s "$UNSIGNED_APK" ]]; then
  echo "Keystore or unsigned APK is missing." >&2
  exit 1
fi

BUILD_TOOLS_ROOT="$SRC_DIR/third_party/android_sdk/public/build-tools"
APKSIGNER="$(find "$BUILD_TOOLS_ROOT" -type f -name apksigner -print \
  | sort -V | tail -1)"
ZIPALIGN="$(find "$BUILD_TOOLS_ROOT" -type f -name zipalign -print \
  | sort -V | tail -1)"

if [[ -z "$APKSIGNER" || -z "$ZIPALIGN" ]]; then
  echo "Android build tools were not found under $BUILD_TOOLS_ROOT" >&2
  exit 1
fi

rm -f "$ALIGNED_APK" "$SIGNED_APK"
"$ZIPALIGN" -f -p 4 "$UNSIGNED_APK" "$ALIGNED_APK"
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-type PKCS12 \
  --ks-key-alias "$KEY_ALIAS" \
  --ks-pass env:ANDROID_KEYSTORE_PASSWORD \
  --key-pass env:ANDROID_KEYSTORE_PASSWORD \
  --out "$SIGNED_APK" \
  "$ALIGNED_APK"

rm -f "$ALIGNED_APK"
echo "Signed APK: $SIGNED_APK"

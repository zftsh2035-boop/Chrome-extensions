#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

APK="${1:-$DIST_DIR/Chromium-ARMv7-Extensions-signed.apk}"
EXPECTED_CERT_SHA256="${EXPECTED_CERT_SHA256:-90266730e98c8a40c53694f06c33ab8201968afea039e3ce7347fd7f42ead4f2}"

if [[ ! -s "$APK" ]]; then
  echo "APK is missing: $APK" >&2
  exit 1
fi

ABI_LIST="$(unzip -Z1 "$APK" \
  | sed -n 's#^lib/\([^/][^/]*\)/.*#\1#p' \
  | sort -u)"
if [[ "$ABI_LIST" != "armeabi-v7a" ]]; then
  echo "Unexpected APK ABI set: ${ABI_LIST:-none}" >&2
  exit 1
fi

BUILD_TOOLS_ROOT="$SRC_DIR/third_party/android_sdk/public/build-tools"
APKSIGNER="$(find "$BUILD_TOOLS_ROOT" -type f -name apksigner -print \
  | sort -V | tail -1)"
AAPT2="$(find "$BUILD_TOOLS_ROOT" -type f -name aapt2 -print \
  | sort -V | tail -1)"

"$APKSIGNER" verify --verbose --print-certs "$APK"
CERT_SHA256="$($APKSIGNER verify --print-certs "$APK" 2>/dev/null \
  | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' \
  | tr -d ':' \
  | tr '[:upper:]' '[:lower:]' \
  | head -1)"
if [[ "$CERT_SHA256" != "$EXPECTED_CERT_SHA256" ]]; then
  echo "Unexpected signing certificate: $CERT_SHA256" >&2
  exit 1
fi

BADGING="$($AAPT2 dump badging "$APK")"
grep -q "package: name='org.chromium.chrome'" <<<"$BADGING"
grep -q "native-code: 'armeabi-v7a'" <<<"$BADGING"

FLAGS_DIR="$OUT_DIR/gen/extensions/buildflags"
if [[ -d "$FLAGS_DIR" ]]; then
  grep -R -E -q \
    'ENABLE_DESKTOP_ANDROID_EXTENSIONS.*(true|1)' "$FLAGS_DIR"
  grep -R -E -q 'ENABLE_EXTENSIONS_CORE.*(true|1)' "$FLAGS_DIR"
fi

sha256sum "$APK" "$DIST_DIR/build-metadata.json"
echo "APK verification passed."

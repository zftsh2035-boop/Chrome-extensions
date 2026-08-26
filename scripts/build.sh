#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

if [[ ! -f "$SRC_DIR/chrome/VERSION" || ! -s "$RESOLVED_REVISION_FILE" ]]; then
  echo "Chromium checkout is missing. Run scripts/bootstrap.sh first." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp "$REPO_ROOT/config/args.gn" "$OUT_DIR/args.gn"

(
  cd "$SRC_DIR"
  gn gen "$OUT_DIR" --fail-on-unused-args

  # Fail before the expensive compilation if upstream no longer maps the
  # Desktop Android configuration to its extension build flags.
  gn args "$OUT_DIR" --list=is_desktop_android \
    | grep -q 'Current value.*true\|is_desktop_android = true'
  gn args "$OUT_DIR" --list=enable_desktop_android_extensions \
    | grep -q 'Current value.*true\|enable_desktop_android_extensions = true'

  autoninja -C "$OUT_DIR" -j "${NINJA_JOBS:-$(nproc)}" chrome_public_apk
)

APK="$OUT_DIR/apks/ChromePublic.apk"
if [[ ! -s "$APK" ]]; then
  echo "Expected APK was not produced: $APK" >&2
  exit 1
fi

cp "$APK" "$DIST_DIR/Chromium-ARMv7-Extensions-unsigned.apk"

VERSION="$(chromium_version_from_source)"
COMMIT="$(chromium_commit_from_source)"
POSITION="$(chromium_commit_position_from_source)"
cat > "$DIST_DIR/build-metadata.json" <<JSON
{
  "chromium_version": "$VERSION",
  "chromium_commit": "$COMMIT",
  "chromium_commit_position": "$POSITION",
  "target_cpu": "arm",
  "android_abi": "armeabi-v7a",
  "is_desktop_android": true,
  "package_name": "org.chromium.chrome"
}
JSON

echo "Unsigned APK: $DIST_DIR/Chromium-ARMv7-Extensions-unsigned.apk"

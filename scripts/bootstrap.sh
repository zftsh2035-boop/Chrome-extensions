#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

load_pinned_revision
REQUESTED_REF="${CHROMIUM_REF:-$CHROMIUM_COMMIT}"

if [[ ! -d "$DEPOT_TOOLS_DIR/.git" ]]; then
  git clone --depth=1 \
    https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    "$DEPOT_TOOLS_DIR"
fi

mkdir -p "$CHECKOUT_ROOT"

# Configure the checkout before the first sync. The upstream "small"
# configuration omits optional benchmark/test data. WebView CTS archives and
# Robolectric SDK images are also test-only and together consume many GB; the
# chrome_public_apk target does not depend on either package.
cat > "$CHECKOUT_ROOT/.gclient" <<'GCLIENT'
solutions = [
  {
    "name": "src",
    "url": "https://chromium.googlesource.com/chromium/src.git",
    "custom_deps": {
      "src/android_webview/tools/cts_archive/cipd": None,
      "src/third_party/robolectric/cipd": None,
    },
    "custom_vars": {
      "checkout_configuration": "small",
    },
  },
]
target_os = ["android"]
target_os_only = True
GCLIENT

(
  cd "$CHECKOUT_ROOT"
  gclient sync --nohooks --no-history --jobs="${GCLIENT_JOBS:-4}" \
    --revision "src@$REQUESTED_REF"
)

RESOLVED_COMMIT="$(git -C "$SRC_DIR" rev-parse HEAD)"

if command -v sudo >/dev/null 2>&1; then
  sudo "$SRC_DIR/build/install-build-deps.sh" --no-prompt --no-syms \
    --lib32 --arm --no-chromeos-fonts
fi

(
  cd "$SRC_DIR"
  gclient runhooks
)

echo "Chromium $(chromium_version_from_source)"
echo "Commit $(git -C "$SRC_DIR" rev-parse HEAD)"
echo "Commit position $(chromium_commit_position_from_source)"

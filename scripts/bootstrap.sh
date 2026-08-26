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
RESOLVED_POSITION="$(chromium_commit_position_from_source)"
RESOLVED_TIMESTAMP="$(git -C "$SRC_DIR" log -1 --format=%ct)"
cat > "$RESOLVED_REVISION_FILE" <<ENV
RESOLVED_CHROMIUM_COMMIT=$RESOLVED_COMMIT
RESOLVED_CHROMIUM_COMMIT_POSITION=$RESOLVED_POSITION
RESOLVED_CHROMIUM_COMMIT_TIMESTAMP=$RESOLVED_TIMESTAMP
ENV

# Chromium's lastchange utility supports these variables for source archives
# without Git metadata. Export them before hooks and keep them for the build.
export BASE_COMMIT_HASH="$RESOLVED_COMMIT"
export BASE_COMMIT_SUBMISSION_MS="$((RESOLVED_TIMESTAMP * 1000))"
df -h / "$REPO_ROOT"

(
  cd "$SRC_DIR"
  gclient runhooks
)

# target_os_only keeps the checkout compact, but chrome_public_apk still builds
# a few x64 host tools (for example Perfetto's trace processor). Install their
# hermetic Linux sysroot explicitly before discarding Git metadata and caches.
python3 "$SRC_DIR/build/linux/sysroot_scripts/install-sysroot.py" --arch=amd64
python3 "$SRC_DIR/build/linux/sysroot_scripts/install-sysroot.py" --arch=i386

df -h / "$REPO_ROOT"

# A shallow gclient checkout still stores a second copy of source content in
# Git object databases. Hooks are finished and Chromium supports source-archive
# builds through BASE_COMMIT_*, so discard only VCS metadata before compiling.
find "$CHECKOUT_ROOT" -name .git -prune -print0 \
  | xargs -0 --no-run-if-empty rm -rf --
rm -rf -- "$WORK_ROOT/.cache"
df -h / "$REPO_ROOT"

echo "Chromium $(chromium_version_from_source)"
echo "Commit $RESOLVED_COMMIT"
echo "Commit position $RESOLVED_POSITION"

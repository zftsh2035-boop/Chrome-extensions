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

if [[ ! -d "$SRC_DIR/.git" ]]; then
  mkdir -p "$CHECKOUT_ROOT"
  (
    cd "$CHECKOUT_ROOT"
    fetch --nohooks --nohistory android
  )
fi

if [[ "$REQUESTED_REF" != "main" && "$REQUESTED_REF" != "refs/heads/main" ]]; then
  if ! git -C "$SRC_DIR" cat-file -e "$REQUESTED_REF^{commit}" 2>/dev/null; then
    git -C "$SRC_DIR" fetch --depth=1 origin "$REQUESTED_REF" || {
      git -C "$SRC_DIR" fetch --depth=128 origin main
    }
  fi
  git -C "$SRC_DIR" checkout --detach "$REQUESTED_REF"
else
  git -C "$SRC_DIR" fetch --depth=1 origin main
  git -C "$SRC_DIR" checkout --detach FETCH_HEAD
fi

RESOLVED_COMMIT="$(git -C "$SRC_DIR" rev-parse HEAD)"

(
  cd "$CHECKOUT_ROOT"
  gclient sync --nohooks --no-history --jobs="${GCLIENT_JOBS:-4}" \
    --revision "src@$RESOLVED_COMMIT"
)

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

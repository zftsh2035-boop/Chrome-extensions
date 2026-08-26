#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${CHROMIUM_WORK_ROOT:-$REPO_ROOT/.work}"
DEPOT_TOOLS_DIR="$WORK_ROOT/depot_tools"
CHECKOUT_ROOT="$WORK_ROOT/chromium"
SRC_DIR="$CHECKOUT_ROOT/src"
OUT_DIR="$SRC_DIR/out/Armv7Extensions"
DIST_DIR="$REPO_ROOT/dist"
RESOLVED_REVISION_FILE="$WORK_ROOT/resolved-chromium.env"

export PATH="$DEPOT_TOOLS_DIR:$PATH"
export VPYTHON_VIRTUALENV_ROOT="${VPYTHON_VIRTUALENV_ROOT:-$WORK_ROOT/.vpython-root}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$WORK_ROOT/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$WORK_ROOT/.config}"
export GOCACHE="${GOCACHE:-$WORK_ROOT/.cache/go-build}"

mkdir -p "$WORK_ROOT" "$DIST_DIR" "$VPYTHON_VIRTUALENV_ROOT" \
  "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$GOCACHE"

if [[ -s "$RESOLVED_REVISION_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$RESOLVED_REVISION_FILE"
  export BASE_COMMIT_HASH="$RESOLVED_CHROMIUM_COMMIT"
  export BASE_COMMIT_SUBMISSION_MS="$((RESOLVED_CHROMIUM_COMMIT_TIMESTAMP * 1000))"
fi

load_pinned_revision() {
  # shellcheck disable=SC1091
  source "$REPO_ROOT/config/chromium.env"
  export CHROMIUM_VERSION CHROMIUM_COMMIT CHROMIUM_COMMIT_POSITION
}

chromium_version_from_source() {
  local version_file="$SRC_DIR/chrome/VERSION"
  awk -F= '
    $1 == "MAJOR" { major=$2 }
    $1 == "MINOR" { minor=$2 }
    $1 == "BUILD" { build=$2 }
    $1 == "PATCH" { patch=$2 }
    END { printf "%s.%s.%s.%s", major, minor, build, patch }
  ' "$version_file"
}

chromium_commit_from_source() {
  if [[ -s "$RESOLVED_REVISION_FILE" ]]; then
    (
      # shellcheck disable=SC1090
      source "$RESOLVED_REVISION_FILE"
      printf '%s\n' "$RESOLVED_CHROMIUM_COMMIT"
    )
  else
    git -C "$SRC_DIR" rev-parse HEAD
  fi
}

chromium_commit_position_from_source() {
  if [[ -s "$RESOLVED_REVISION_FILE" ]]; then
    (
      # shellcheck disable=SC1090
      source "$RESOLVED_REVISION_FILE"
      printf '%s\n' "$RESOLVED_CHROMIUM_COMMIT_POSITION"
    )
  else
    git -C "$SRC_DIR" log -1 --format=%B \
      | sed -n 's/.*Cr-Commit-Position: refs\/heads\/main@{#\([0-9][0-9]*\)}.*/\1/p' \
      | tail -1
  fi
}

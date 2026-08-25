#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  echo "Refusing to clean SDK directories outside GitHub Actions." >&2
  exit 1
fi

# Chromium supplies its own Android SDK/toolchain. These large preinstalled
# runner components are unrelated to this build and can be removed safely from
# the disposable Actions VM.
PATHS=(
  /usr/local/lib/android
  /usr/share/dotnet
  /opt/ghc
  /usr/local/share/boost
  /opt/hostedtoolcache/CodeQL
)

for path in "${PATHS[@]}"; do
  if [[ -e "$path" ]]; then
    sudo rm -rf -- "$path"
  fi
done

if command -v docker >/dev/null 2>&1; then
  docker image prune --all --force || true
fi

df -h /

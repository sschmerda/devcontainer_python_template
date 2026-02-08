#!/usr/bin/env sh
set -eu

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/quarto-environment"
LOCK_FILE="${ENV_DIR}/quarto-lock.env"

if ! command -v quarto >/dev/null 2>&1; then
  echo "quarto is not installed in this container."
  exit 1
fi

VERSION="$(quarto --version | awk 'NR==1{print $1}')"
if [ -z "$VERSION" ]; then
  echo "Unable to detect installed Quarto version."
  exit 1
fi

TAG="v${VERSION}"
AMD64_ASSET="quarto-${VERSION}-linux-amd64.tar.gz"
ARM64_ASSET="quarto-${VERSION}-linux-arm64.tar.gz"
AMD64_URL="https://github.com/quarto-dev/quarto-cli/releases/download/${TAG}/${AMD64_ASSET}"
ARM64_URL="https://github.com/quarto-dev/quarto-cli/releases/download/${TAG}/${ARM64_ASSET}"

# Validate both assets exist so the lockfile is cross-arch reproducible.
if ! curl -fsI "$AMD64_URL" >/dev/null; then
  echo "Missing Quarto asset: $AMD64_URL"
  exit 1
fi
if ! curl -fsI "$ARM64_URL" >/dev/null; then
  echo "Missing Quarto asset: $ARM64_URL"
  exit 1
fi

ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
{
  printf '# Created: %s\n' "$ts"
  printf 'QUARTO_TAG=%s\n' "$TAG"
  printf 'QUARTO_VERSION=%s\n' "$VERSION"
  printf 'QUARTO_LINUX_AMD64_URL=%s\n' "$AMD64_URL"
  printf 'QUARTO_LINUX_ARM64_URL=%s\n' "$ARM64_URL"
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

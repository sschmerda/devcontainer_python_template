#!/usr/bin/env sh
set -eu

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/quarto-environment"
LOCK_FILE="${ENV_DIR}/quarto-lock.env"
LATEST_API="https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
RELEASE_JSON="$(curl -fsSL "$LATEST_API")"
TAG="$(printf '%s\n' "$RELEASE_JSON" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
if [ -z "$TAG" ]; then
  echo "Unable to determine latest Quarto release tag from GitHub."
  exit 1
fi
VERSION="${TAG#v}"
AMD64_ASSET="quarto-${VERSION}-linux-amd64.tar.gz"
ARM64_ASSET="quarto-${VERSION}-linux-arm64.tar.gz"
AMD64_URL="https://github.com/quarto-dev/quarto-cli/releases/download/${TAG}/${AMD64_ASSET}"
ARM64_URL="https://github.com/quarto-dev/quarto-cli/releases/download/${TAG}/${ARM64_ASSET}"
TMP_DIR="$(mktemp -d)"
AMD64_FILE="${TMP_DIR}/${AMD64_ASSET}"
ARM64_FILE="${TMP_DIR}/${ARM64_ASSET}"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Validate both assets exist so the lockfile is cross-arch reproducible.
if ! curl -fsI "$AMD64_URL" >/dev/null; then
  echo "Missing Quarto asset: $AMD64_URL"
  exit 1
fi
if ! curl -fsI "$ARM64_URL" >/dev/null; then
  echo "Missing Quarto asset: $ARM64_URL"
  exit 1
fi

curl -fsSL "$AMD64_URL" -o "$AMD64_FILE"
curl -fsSL "$ARM64_URL" -o "$ARM64_FILE"
AMD64_SHA256="$(sha256sum "$AMD64_FILE" | awk '{print $1}')"
ARM64_SHA256="$(sha256sum "$ARM64_FILE" | awk '{print $1}')"
if [ -z "$AMD64_SHA256" ] || [ -z "$ARM64_SHA256" ]; then
  echo "Failed to compute Quarto asset checksums."
  exit 1
fi

ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
{
  printf '# Created: %s\n' "$ts"
  printf 'QUARTO_TAG=%s\n' "$TAG"
  printf 'QUARTO_VERSION=%s\n' "$VERSION"
  printf 'QUARTO_LINUX_AMD64_URL=%s\n' "$AMD64_URL"
  printf 'QUARTO_LINUX_ARM64_URL=%s\n' "$ARM64_URL"
  printf 'QUARTO_LINUX_AMD64_SHA256=%s\n' "$AMD64_SHA256"
  printf 'QUARTO_LINUX_ARM64_SHA256=%s\n' "$ARM64_SHA256"
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

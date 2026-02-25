#!/usr/bin/env sh
set -eu

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/micromamba-environment"
LOCK_FILE="${ENV_DIR}/micromamba-lock.env"
LATEST_API="https://api.github.com/repos/mamba-org/micromamba-releases/releases/latest"
RELEASE_JSON="$(curl -fsSL "$LATEST_API")"
TAG="$(printf '%s\n' "$RELEASE_JSON" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
if [ -z "$TAG" ]; then
  echo "Unable to determine latest micromamba release tag from GitHub."
  exit 1
fi
VERSION="${TAG#v}"
URLS="$(printf '%s\n' "$RELEASE_JSON" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p')"
AMD64_URL="$(printf '%s\n' "$URLS" | grep '/micromamba-linux-64\.tar\.bz2$' | head -n 1 || true)"
if [ -z "$AMD64_URL" ]; then
  AMD64_URL="$(printf '%s\n' "$URLS" | grep '/micromamba-linux-64$' | head -n 1 || true)"
fi
ARM64_URL="$(printf '%s\n' "$URLS" | grep '/micromamba-linux-aarch64\.tar\.bz2$' | head -n 1 || true)"
if [ -z "$ARM64_URL" ]; then
  ARM64_URL="$(printf '%s\n' "$URLS" | grep '/micromamba-linux-aarch64$' | head -n 1 || true)"
fi
if [ -z "$AMD64_URL" ] || [ -z "$ARM64_URL" ]; then
  echo "Unable to find expected micromamba assets for ${TAG}."
  exit 1
fi
TMP_DIR="$(mktemp -d)"
AMD64_FILE="${TMP_DIR}/micromamba-linux-64-${VERSION}"
ARM64_FILE="${TMP_DIR}/micromamba-linux-aarch64-${VERSION}"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Validate both assets exist so the lockfile is cross-arch reproducible.
if ! curl -fsSL "$AMD64_URL" -o /dev/null; then
  echo "Missing micromamba asset: $AMD64_URL"
  exit 1
fi
if ! curl -fsSL "$ARM64_URL" -o /dev/null; then
  echo "Missing micromamba asset: $ARM64_URL"
  exit 1
fi

curl -fsSL "$AMD64_URL" -o "$AMD64_FILE"
curl -fsSL "$ARM64_URL" -o "$ARM64_FILE"
AMD64_SHA256="$(sha256sum "$AMD64_FILE" | awk '{print $1}')"
ARM64_SHA256="$(sha256sum "$ARM64_FILE" | awk '{print $1}')"
if [ -z "$AMD64_SHA256" ] || [ -z "$ARM64_SHA256" ]; then
  echo "Failed to compute micromamba asset checksums."
  exit 1
fi

ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
{
  printf '# Created: %s\n' "$ts"
  printf 'MICROMAMBA_TAG=%s\n' "$TAG"
  printf 'MICROMAMBA_VERSION=%s\n' "$VERSION"
  printf 'MICROMAMBA_LINUX_AMD64_URL=%s\n' "$AMD64_URL"
  printf 'MICROMAMBA_LINUX_ARM64_URL=%s\n' "$ARM64_URL"
  printf 'MICROMAMBA_LINUX_AMD64_SHA256=%s\n' "$AMD64_SHA256"
  printf 'MICROMAMBA_LINUX_ARM64_SHA256=%s\n' "$ARM64_SHA256"
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

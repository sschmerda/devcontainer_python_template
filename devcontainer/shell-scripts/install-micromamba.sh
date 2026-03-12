#!/usr/bin/env bash
set -euo pipefail

ARCH="$(uname -m)"
WORKDIR="$(mktemp -d)"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"
LOCK_FILE="/tmp/micromamba-environment/micromamba-lock.env"
MICROMAMBA_REPO="mamba-org/micromamba-releases"
MICROMAMBA_RELEASES_LATEST_DOWNLOAD_URL_TEMPLATE="https://github.com/${MICROMAMBA_REPO}/releases/latest/download/%s.tar.bz2"
MAMBA_CHANNEL_ALIAS_URL="https://conda.anaconda.org"

asset_basename_for_arch() {
  case "$ARCH" in
    x86_64|amd64)
      echo "micromamba-linux-64"
      ;;
    aarch64|arm64)
      echo "micromamba-linux-aarch64"
      ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
}

resolve_latest_url() {
  local base
  base="$(asset_basename_for_arch)"
  URL="$(printf "$MICROMAMBA_RELEASES_LATEST_DOWNLOAD_URL_TEMPLATE" "$base")"
  VERSION="latest"
  echo ">>> Selected micromamba release: latest (${base})"
}

install_from_download() {
  local url="$1"
  local expected_sha256="${2:-}"
  local archive_path actual_sha256 src

  archive_path="${WORKDIR}/micromamba-download"
  curl -fL --retry 4 --retry-delay 3 --retry-all-errors "$url" -o "$archive_path"

  if [ -n "$expected_sha256" ]; then
    actual_sha256="$(sha256sum "$archive_path" | awk '{print $1}')"
    if [ "$actual_sha256" != "$expected_sha256" ]; then
      echo "Micromamba checksum mismatch for locked asset."
      echo "Expected: $expected_sha256"
      echo "Actual:   $actual_sha256"
      exit 1
    fi
  fi

  if tar -tf "$archive_path" >/dev/null 2>&1; then
    if tar -tf "$archive_path" | grep -q '^bin/micromamba$'; then
      tar -xf "$archive_path" -C "$WORKDIR" bin/micromamba
      src="${WORKDIR}/bin/micromamba"
    elif tar -tf "$archive_path" | grep -q '^micromamba$'; then
      tar -xf "$archive_path" -C "$WORKDIR" micromamba
      src="${WORKDIR}/micromamba"
    else
      echo "Micromamba binary not found in downloaded archive."
      exit 1
    fi
  else
    src="$archive_path"
    chmod +x "$src"
  fi

  mkdir -p "$BIN_DIR"
  export PATH="$BIN_DIR:$PATH"
  export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"
  export MAMBA_CHANNEL_ALIAS="$MAMBA_CHANNEL_ALIAS_URL"
  mv "$src" "$BIN_DIR/micromamba"
}

echo ">>> Installing micromamba..."

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ ! -f "$LOCK_FILE" ]; then
    echo "Micromamba lockfile does not exist: $LOCK_FILE"
    exit 1
  fi
  # shellcheck disable=SC1090
  . "$LOCK_FILE"
  case "$ARCH" in
    x86_64|amd64)
      URL="${MICROMAMBA_LINUX_AMD64_URL:-}"
      SHA256="${MICROMAMBA_LINUX_AMD64_SHA256:-}"
      ;;
    aarch64|arm64)
      URL="${MICROMAMBA_LINUX_ARM64_URL:-}"
      SHA256="${MICROMAMBA_LINUX_ARM64_SHA256:-}"
      ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
  if [ -z "${URL:-}" ]; then
    echo "Missing locked micromamba URL for architecture: $ARCH"
    exit 1
  fi
  if [ -z "${SHA256:-}" ]; then
    echo "Missing locked micromamba SHA256 for architecture: $ARCH"
    exit 1
  fi
  if [ -z "${MICROMAMBA_TAG:-}" ] && [ -z "${MICROMAMBA_VERSION:-}" ]; then
    echo "Missing MICROMAMBA_TAG or MICROMAMBA_VERSION in $LOCK_FILE"
    exit 1
  fi
  echo ">>> Installing locked micromamba: ${MICROMAMBA_TAG:-$MICROMAMBA_VERSION}"
  install_from_download "$URL" "$SHA256"
else
  resolve_latest_url
  install_from_download "$URL"
fi

rm -rf "$WORKDIR"
echo ">>> Micromamba installation completed."

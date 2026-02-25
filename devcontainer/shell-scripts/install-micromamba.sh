#!/usr/bin/env bash
set -euo pipefail

ARCH="$(uname -m)"
WORKDIR="$(mktemp -d)"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"
LOCK_FILE="/tmp/micromamba-environment/micromamba-lock.env"
GITHUB_LATEST_API="https://api.github.com/repos/mamba-org/micromamba-releases/releases/latest"

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

pick_asset_url() {
  local urls="$1"
  local base="$2"
  local url
  url="$(printf '%s\n' "$urls" | grep "/${base}\\.tar\\.bz2$" | head -n 1 || true)"
  if [ -z "$url" ]; then
    url="$(printf '%s\n' "$urls" | grep "/${base}$" | head -n 1 || true)"
  fi
  printf '%s' "$url"
}

resolve_latest_url() {
  local release_json tag urls base url
  release_json="$(curl -fsSL "$GITHUB_LATEST_API")"
  tag="$(printf '%s\n' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [ -z "$tag" ]; then
    echo "Unable to determine latest micromamba release tag from GitHub."
    exit 1
  fi
  urls="$(printf '%s\n' "$release_json" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p')"
  base="$(asset_basename_for_arch)"
  url="$(pick_asset_url "$urls" "$base")"
  if [ -z "$url" ]; then
    echo "Unable to find micromamba asset for ${ARCH} in GitHub release ${tag}."
    exit 1
  fi
  URL="$url"
  VERSION="${tag#v}"
  echo ">>> Selected micromamba release: ${tag}"
}

install_from_download() {
  local url="$1"
  local expected_sha256="${2:-}"
  local archive_path actual_sha256 src

  archive_path="${WORKDIR}/micromamba-download"
  curl -fLs "$url" -o "$archive_path"

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
  export MAMBA_CHANNEL_ALIAS="https://conda.anaconda.org"
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
  echo ">>> Installing locked micromamba: ${MICROMAMBA_TAG:-${MICROMAMBA_VERSION:-unknown}}"
  install_from_download "$URL" "$SHA256"
else
  resolve_latest_url
  install_from_download "$URL"
fi

rm -rf "$WORKDIR"
echo ">>> Micromamba installation completed."

#!/usr/bin/env bash
eet -euo pipefail
ARCH=$(uname -m)
LOCK_FILE="/tmp/additional-binaries-environment/additional-binaries-root-lock.env"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-4}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-10}"

echo ">>> Installing additional system packages..."

arch_suffix() {
  case "$ARCH" in
  x86_64 | amd64)
    printf '%s' "AMD64"
    ;;
  aarch64 | arm64)
    printf '%s' "ARM64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
  esac
}

retry_run() {
  attempt=1
  while [ "$attempt" -le "$RETRY_ATTEMPTS" ]; do
    if "$@"; then
      return 0
    fi
    if [ "$attempt" -lt "$RETRY_ATTEMPTS" ]; then
      sleep "$((RETRY_DELAY_SECONDS * attempt))"
    fi
    attempt=$((attempt + 1))
  done
  return 1
}

fetch_latest_tag() {
  repo="$1"
  retry_run curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" |
    sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' |
    head -n 1
}

download_file() {
  url="$1"
  out="$2"
  retry_run curl -fL --retry 4 --retry-delay 3 --retry-all-errors "$url" -o "$out"
}

verify_sha256() {
  file="$1"
  expected="$2"
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [ "$actual" != "$expected" ]; then
    echo "Checksum mismatch for $file"
    echo "Expected: $expected"
    echo "Actual:   $actual"
    exit 1
  fi
}

FZF_URL=""
FZF_SHA256=""
NVIM_URL=""
NVIM_SHA256=""
LSD_URL=""
LSD_SHA256=""

resolve_locked_urls() {
  if [ ! -f "$LOCK_FILE" ]; then
    echo "Additional binaries lockfile does not exist: $LOCK_FILE"
    exit 1
  fi
  # shellcheck disable=SC1090
  . "$LOCK_FILE"
  ARCH_SUFFIX="$(arch_suffix)"
  FZF_URL_VAR="FZF_LINUX_${ARCH_SUFFIX}_URL"
  FZF_SHA_VAR="FZF_LINUX_${ARCH_SUFFIX}_SHA256"
  NVIM_URL_VAR="NEOVIM_LINUX_${ARCH_SUFFIX}_URL"
  NVIM_SHA_VAR="NEOVIM_LINUX_${ARCH_SUFFIX}_SHA256"
  LSD_URL_VAR="LSD_LINUX_${ARCH_SUFFIX}_URL"
  LSD_SHA_VAR="LSD_LINUX_${ARCH_SUFFIX}_SHA256"

  FZF_URL="${!FZF_URL_VAR:-}"
  FZF_SHA256="${!FZF_SHA_VAR:-}"
  NVIM_URL="${!NVIM_URL_VAR:-}"
  NVIM_SHA256="${!NVIM_SHA_VAR:-}"
  LSD_URL="${!LSD_URL_VAR:-}"
  LSD_SHA256="${!LSD_SHA_VAR:-}"

  [ -n "$FZF_URL" ] && [ -n "$FZF_SHA256" ] || {
    echo "Missing locked fzf vars for ${ARCH_SUFFIX}"
    exit 1
  }
  [ -n "$NVIM_URL" ] && [ -n "$NVIM_SHA256" ] || {
    echo "Missing locked neovim vars for ${ARCH_SUFFIX}"
    exit 1
  }
  [ -n "$LSD_URL" ] && [ -n "$LSD_SHA256" ] || {
    echo "Missing locked lsd vars for ${ARCH_SUFFIX}"
    exit 1
  }
}

resolve_latest_urls() {
  FZF_TAG="$(fetch_latest_tag "junegunn/fzf")"
  NVIM_TAG="$(fetch_latest_tag "neovim/neovim")"
  LSD_TAG="$(fetch_latest_tag "lsd-rs/lsd")"
  if [ -z "$FZF_TAG" ] || [ -z "$NVIM_TAG" ] || [ -z "$LSD_TAG" ]; then
    echo "Unable to resolve latest release tags for additional binaries."
    exit 1
  fi

  case "$ARCH" in
  x86_64 | amd64)
    FZF_URL="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_TAG#v}-linux_amd64.tar.gz"
    NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-x86_64.tar.gz"
    LSD_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_TAG}/lsd-musl_${LSD_TAG#v}_amd64.deb"
    ;;
  aarch64 | arm64)
    FZF_URL="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_TAG#v}-linux_arm64.tar.gz"
    NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-arm64.tar.gz"
    LSD_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_TAG}/lsd-musl_${LSD_TAG#v}_arm64.deb"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
  esac
}

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  resolve_locked_urls
else
  resolve_latest_urls
fi

FZF_TAR="/tmp/fzf-install.tar.gz"
download_file "$FZF_URL" "$FZF_TAR"
if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  verify_sha256 "$FZF_TAR" "$FZF_SHA256"
fi
tar -xzf "$FZF_TAR" -C /usr/local/bin
chmod +x /usr/local/bin/fzf
rm -f "$FZF_TAR"

NVIM_TAR="/tmp/nvim-install.tar.gz"
download_file "$NVIM_URL" "$NVIM_TAR"
if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  verify_sha256 "$NVIM_TAR" "$NVIM_SHA256"
fi
mkdir -p /usr/local
tar -xzf "$NVIM_TAR" -C /usr/local
ln -sf /usr/local/nvim-linux*/bin/nvim /usr/local/bin/nvim
rm -f "$NVIM_TAR"

LSD_DEB="/tmp/lsd-install.deb"
download_file "$LSD_URL" "$LSD_DEB"
if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  verify_sha256 "$LSD_DEB" "$LSD_SHA256"
fi
dpkg -i "$LSD_DEB"
rm -f "$LSD_DEB"

echo ">>> Additional system software installation completed."

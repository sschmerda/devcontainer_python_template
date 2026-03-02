#!/usr/bin/env sh
set -eu

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/additional-binaries-environment"
LOCK_FILE="${ENV_DIR}/additional-binaries-root-lock.env"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fetch_tag() {
  repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

download_and_sha() {
  url="$1"
  out="$2"
  curl -fL --retry 4 --retry-delay 3 --retry-all-errors "$url" -o "$out"
  sha256sum "$out" | awk '{print $1}'
}

FZF_TAG="$(fetch_tag "junegunn/fzf")"
NEOVIM_TAG="$(fetch_tag "neovim/neovim")"
LSD_TAG="$(fetch_tag "lsd-rs/lsd")"

if [ -z "$FZF_TAG" ] || [ -z "$NEOVIM_TAG" ] || [ -z "$LSD_TAG" ]; then
  echo "Unable to determine latest tags for fzf/neovim/lsd."
  exit 1
fi

FZF_VERSION="${FZF_TAG#v}"
NEOVIM_VERSION="${NEOVIM_TAG#v}"
LSD_VERSION="${LSD_TAG#v}"

FZF_LINUX_AMD64_URL="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
FZF_LINUX_ARM64_URL="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_VERSION}-linux_arm64.tar.gz"
NEOVIM_LINUX_AMD64_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_TAG}/nvim-linux-x86_64.tar.gz"
NEOVIM_LINUX_ARM64_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_TAG}/nvim-linux-arm64.tar.gz"
LSD_LINUX_AMD64_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_TAG}/lsd-musl_${LSD_VERSION}_amd64.deb"
LSD_LINUX_ARM64_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_TAG}/lsd-musl_${LSD_VERSION}_arm64.deb"

FZF_LINUX_AMD64_SHA256="$(download_and_sha "$FZF_LINUX_AMD64_URL" "$TMP_DIR/fzf-amd64.tar.gz")"
FZF_LINUX_ARM64_SHA256="$(download_and_sha "$FZF_LINUX_ARM64_URL" "$TMP_DIR/fzf-arm64.tar.gz")"
NEOVIM_LINUX_AMD64_SHA256="$(download_and_sha "$NEOVIM_LINUX_AMD64_URL" "$TMP_DIR/nvim-amd64.tar.gz")"
NEOVIM_LINUX_ARM64_SHA256="$(download_and_sha "$NEOVIM_LINUX_ARM64_URL" "$TMP_DIR/nvim-arm64.tar.gz")"
LSD_LINUX_AMD64_SHA256="$(download_and_sha "$LSD_LINUX_AMD64_URL" "$TMP_DIR/lsd-amd64.deb")"
LSD_LINUX_ARM64_SHA256="$(download_and_sha "$LSD_LINUX_ARM64_URL" "$TMP_DIR/lsd-arm64.deb")"

mkdir -p "$ENV_DIR"
{
  printf '# Created: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf 'FZF_TAG=%s\n' "$FZF_TAG"
  printf 'FZF_VERSION=%s\n' "$FZF_VERSION"
  printf 'FZF_LINUX_AMD64_URL=%s\n' "$FZF_LINUX_AMD64_URL"
  printf 'FZF_LINUX_ARM64_URL=%s\n' "$FZF_LINUX_ARM64_URL"
  printf 'FZF_LINUX_AMD64_SHA256=%s\n' "$FZF_LINUX_AMD64_SHA256"
  printf 'FZF_LINUX_ARM64_SHA256=%s\n' "$FZF_LINUX_ARM64_SHA256"
  printf 'NEOVIM_TAG=%s\n' "$NEOVIM_TAG"
  printf 'NEOVIM_VERSION=%s\n' "$NEOVIM_VERSION"
  printf 'NEOVIM_LINUX_AMD64_URL=%s\n' "$NEOVIM_LINUX_AMD64_URL"
  printf 'NEOVIM_LINUX_ARM64_URL=%s\n' "$NEOVIM_LINUX_ARM64_URL"
  printf 'NEOVIM_LINUX_AMD64_SHA256=%s\n' "$NEOVIM_LINUX_AMD64_SHA256"
  printf 'NEOVIM_LINUX_ARM64_SHA256=%s\n' "$NEOVIM_LINUX_ARM64_SHA256"
  printf 'LSD_TAG=%s\n' "$LSD_TAG"
  printf 'LSD_VERSION=%s\n' "$LSD_VERSION"
  printf 'LSD_LINUX_AMD64_URL=%s\n' "$LSD_LINUX_AMD64_URL"
  printf 'LSD_LINUX_ARM64_URL=%s\n' "$LSD_LINUX_ARM64_URL"
  printf 'LSD_LINUX_AMD64_SHA256=%s\n' "$LSD_LINUX_AMD64_SHA256"
  printf 'LSD_LINUX_ARM64_SHA256=%s\n' "$LSD_LINUX_ARM64_SHA256"
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

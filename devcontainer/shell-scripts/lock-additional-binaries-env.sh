#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/additional-binaries-environment"
LIST_FILE="${ENV_DIR}/additional-binaries.list"
CONFIG_DIR="${ENV_DIR}/additional-binaries"
LOCK_FILE="${ENV_DIR}/additional-binaries-lock.env"
TMP_DIR="$(mktemp -d)"
GITHUB_API_BASE_URL="https://api.github.com"
GITHUB_RELEASES_LATEST_URL_TEMPLATE="${GITHUB_API_BASE_URL}/repos/%s/releases/latest"
GITHUB_RELEASE_DOWNLOAD_URL_TEMPLATE="https://github.com/%s/releases/download/%s/%s"

sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "Neither sha256sum nor shasum is available." >&2
    exit 1
  fi
}

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ ! -f "$LIST_FILE" ]; then
  echo "Missing additional binaries list file: $LIST_FILE"
  exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Missing additional binaries config directory: $CONFIG_DIR"
  exit 1
fi

require_var() {
  local name value
  name="$1"
  value="${!name:-}"
  if [ -z "$value" ]; then
    echo "Missing required env var: $name"
    exit 1
  fi
  printf '%s' "$value"
}

assert_install_method() {
  local method
  method="$1"
  case "$method" in
    tar|zip|deb) ;;
    *)
      echo "Unsupported INSTALL_METHOD: $method"
      exit 1
      ;;
  esac
}

list_binaries() {
  awk '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*$/ {next}
    {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print $0}
  ' "$LIST_FILE"
}

reset_binary_vars() {
  unset INSTALL_METHOD REPO GITHUB_VERSION_TAG_PREFIX ASSET_FILE_NAME_AMD64 ASSET_FILE_NAME_ARM64 TAR_BIN_PATH ZIP_BIN_PATH INSTALL_TARGET_PATH TAR_INSTALL_MODE TAR_INSTALL_ROOT_GLOB TAR_INSTALL_DIR
}

load_binary_config() {
  local binary config_file
  binary="$1"
  config_file="${CONFIG_DIR}/${binary}.env"
  if [ ! -f "$config_file" ]; then
    echo "Missing binary config file: $config_file"
    exit 1
  fi
  reset_binary_vars
  # shellcheck disable=SC1090
  . "$config_file"
}

fetch_tag() {
  local repo
  repo="$1"
  curl -fsSL "$(printf "$GITHUB_RELEASES_LATEST_URL_TEMPLATE" "$repo")" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

download_and_sha() {
  local url out
  url="$1"
  out="$2"
  curl -fL --retry 4 --retry-delay 3 --retry-all-errors "$url" -o "$out"
  sha256_file "$out"
}

build_url() {
  local repo tag template version asset
  repo="$1"
  tag="$2"
  template="$3"
  version="$4"
  asset="${template//\{VERSION\}/$version}"
  asset="${asset//\{TAG\}/$tag}"
  printf "$GITHUB_RELEASE_DOWNLOAD_URL_TEMPLATE" "$repo" "$tag" "$asset"
}

mkdir -p "$ENV_DIR"
{
  printf '# Created: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  list_binaries | while IFS= read -r binary; do
    [ -n "$binary" ] || continue
    load_binary_config "$binary"

    install_method="$(require_var INSTALL_METHOD)"
    assert_install_method "$install_method"
    repo="$(require_var REPO)"
    tag_prefix="$(require_var GITHUB_VERSION_TAG_PREFIX)"
    asset_amd64="$(require_var ASSET_FILE_NAME_AMD64)"
    asset_arm64="$(require_var ASSET_FILE_NAME_ARM64)"

    tag="$(fetch_tag "$repo")"
    if [ -z "$tag" ]; then
      echo "Unable to determine latest tag for ${repo}."
      exit 1
    fi
    version="${tag#${tag_prefix}}"

    url_amd64="$(build_url "$repo" "$tag" "$asset_amd64" "$version")"
    url_arm64="$(build_url "$repo" "$tag" "$asset_arm64" "$version")"

    sha_amd64="$(download_and_sha "$url_amd64" "$TMP_DIR/${binary}-amd64.asset")"
    sha_arm64="$(download_and_sha "$url_arm64" "$TMP_DIR/${binary}-arm64.asset")"

    key="$(printf '%s' "$binary" | tr '[:lower:]-' '[:upper:]_')"
    printf '%s_TAG=%s\n' "$key" "$tag"
    printf '%s_VERSION=%s\n' "$key" "$version"
    printf '%s_LINUX_AMD64_URL=%s\n' "$key" "$url_amd64"
    printf '%s_LINUX_ARM64_URL=%s\n' "$key" "$url_arm64"
    printf '%s_LINUX_AMD64_SHA256=%s\n' "$key" "$sha_amd64"
    printf '%s_LINUX_ARM64_SHA256=%s\n' "$key" "$sha_arm64"
  done
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

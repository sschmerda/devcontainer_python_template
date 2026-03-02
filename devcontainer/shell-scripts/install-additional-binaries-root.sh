#!/usr/bin/env bash
set -euo pipefail

ARCH="$(uname -m)"
LIST_FILE="/tmp/additional-binaries-environment/root-binaries.list"
CONFIG_DIR="/tmp/additional-binaries-environment/root-binaries"
LOCK_FILE="/tmp/additional-binaries-environment/additional-binaries-root-lock.env"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-4}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-10}"

echo ">>> Installing additional system packages..."

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

arch_suffix() {
  case "$ARCH" in
    x86_64|amd64) printf '%s' "AMD64" ;;
    aarch64|arm64) printf '%s' "ARM64" ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
}

retry_run() {
  local attempt
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
  local repo
  repo="$1"
  retry_run curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

download_file() {
  local url out
  url="$1"
  out="$2"
  retry_run curl -fL --retry 4 --retry-delay 3 --retry-all-errors "$url" -o "$out"
}

verify_sha256() {
  local file expected actual
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

resolve_locked_url_and_sha() {
  local key arch_var url_var sha_var url sha
  key="$1"

  if [ ! -f "$LOCK_FILE" ]; then
    echo "Additional binaries lockfile does not exist: $LOCK_FILE"
    exit 1
  fi

  # shellcheck disable=SC1090
  . "$LOCK_FILE"

  arch_var="$(arch_suffix)"
  url_var="${key}_LINUX_${arch_var}_URL"
  sha_var="${key}_LINUX_${arch_var}_SHA256"

  url="${!url_var:-}"
  sha="${!sha_var:-}"
  if [ -z "$url" ] || [ -z "$sha" ]; then
    echo "Missing lock values for ${key} (${arch_var}) in $LOCK_FILE"
    exit 1
  fi

  printf '%s|%s\n' "$url" "$sha"
}

resolve_latest_url_for_binary() {
  local repo tag_prefix tag version asset_template asset

  repo="$(require_var REPO)"
  tag_prefix="$(require_var GITHUB_VERSION_TAG_PREFIX)"
  tag="$(fetch_latest_tag "$repo")"
  if [ -z "$tag" ]; then
    echo "Unable to resolve latest release tag for ${repo}"
    exit 1
  fi
  version="${tag#${tag_prefix}}"

  case "$ARCH" in
    x86_64|amd64) asset_template="$(require_var ASSET_FILE_NAME_AMD64)" ;;
    aarch64|arm64) asset_template="$(require_var ASSET_FILE_NAME_ARM64)" ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  asset="${asset_template//\{VERSION\}/$version}"
  asset="${asset//\{TAG\}/$tag}"

  printf '%s\n' "https://github.com/${repo}/releases/download/${tag}/${asset}"
}

install_tar_binary() {
  local archive bin_glob target extract_dir
  local -a matches
  archive="$1"
  bin_glob="$2"
  target="$3"
  extract_dir="$(mktemp -d)"
  tar -xzf "$archive" -C "$extract_dir"
  shopt -s nullglob
  matches=( "$extract_dir"/$bin_glob )
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 0 ]; then
    echo "No binary matched TAR path: $bin_glob"
    rm -rf "$extract_dir"
    exit 1
  fi
  install -Dm0755 "${matches[0]}" "$target"
  rm -rf "$extract_dir"
}

install_tar_tree() {
  local archive root_glob install_dir bin_glob target extract_dir
  local -a roots matches
  archive="$1"
  root_glob="$2"
  install_dir="$3"
  bin_glob="$4"
  target="$5"

  extract_dir="$(mktemp -d)"
  tar -xzf "$archive" -C "$extract_dir"

  shopt -s nullglob
  roots=( "$extract_dir"/$root_glob )
  shopt -u nullglob
  if [ "${#roots[@]}" -eq 0 ]; then
    echo "No extracted root matched TAR_INSTALL_ROOT_GLOB: $root_glob"
    rm -rf "$extract_dir"
    exit 1
  fi

  rm -rf "$install_dir"
  mkdir -p "$(dirname "$install_dir")"
  cp -a "${roots[0]}" "$install_dir"

  shopt -s nullglob
  matches=( "$install_dir"/$bin_glob )
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 0 ]; then
    echo "No binary matched TAR path inside installed tree: $bin_glob"
    rm -rf "$extract_dir"
    exit 1
  fi

  ln -sf "${matches[0]}" "$target"
  rm -rf "$extract_dir"
}

install_zip_binary() {
  local archive bin_glob target extract_dir
  local -a matches
  archive="$1"
  bin_glob="$2"
  target="$3"
  extract_dir="$(mktemp -d)"
  unzip -q "$archive" -d "$extract_dir"
  shopt -s nullglob
  matches=( "$extract_dir"/$bin_glob )
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 0 ]; then
    echo "No binary matched ZIP path: $bin_glob"
    rm -rf "$extract_dir"
    exit 1
  fi
  install -Dm0755 "${matches[0]}" "$target"
  rm -rf "$extract_dir"
}

while IFS= read -r binary; do
  [ -n "$binary" ] || continue
  load_binary_config "$binary"

  install_method="$(require_var INSTALL_METHOD)"
  assert_install_method "$install_method"
  key="$(printf '%s' "$binary" | tr '[:lower:]-' '[:upper:]_')"

  if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
    resolved="$(resolve_locked_url_and_sha "$key")"
    url="${resolved%%|*}"
    sha="${resolved#*|}"
  else
    url="$(resolve_latest_url_for_binary)"
    sha=""
  fi

  asset_file="/tmp/${binary}-install-asset"
  download_file "$url" "$asset_file"
  if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
    verify_sha256 "$asset_file" "$sha"
  fi

  case "$install_method" in
    tar)
      tar_install_mode="${TAR_INSTALL_MODE:-binary}"
      case "$tar_install_mode" in
        binary)
          tar_bin_path="$(require_var TAR_BIN_PATH)"
          install_target="$(require_var INSTALL_TARGET_PATH)"
          install_tar_binary "$asset_file" "$tar_bin_path" "$install_target"
          ;;
        tree)
          tar_install_root_glob="$(require_var TAR_INSTALL_ROOT_GLOB)"
          tar_install_dir="$(require_var TAR_INSTALL_DIR)"
          tar_bin_path="$(require_var TAR_BIN_PATH)"
          install_target="$(require_var INSTALL_TARGET_PATH)"
          install_tar_tree "$asset_file" "$tar_install_root_glob" "$tar_install_dir" "$tar_bin_path" "$install_target"
          ;;
        *)
          echo "Unsupported TAR_INSTALL_MODE: $tar_install_mode"
          exit 1
          ;;
      esac
      ;;
    zip)
      zip_bin_path="$(require_var ZIP_BIN_PATH)"
      install_target="$(require_var INSTALL_TARGET_PATH)"
      install_zip_binary "$asset_file" "$zip_bin_path" "$install_target"
      ;;
    deb)
      dpkg -i "$asset_file"
      ;;
  esac

  rm -f "$asset_file"
done < <(list_binaries)

echo ">>> Additional system software installation completed."

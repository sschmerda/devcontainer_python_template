#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS_LOCK_FILE="${ROOT_DIR}/os-environment/os-lock.env"
LOCK_DIR="${ROOT_DIR}/base-binaries-environment"
LOCK_FILE="${LOCK_DIR}/base-binaries-lock.env"
SNAPSHOT_TS="$(date -u '+%Y%m%dT%H%M%SZ')"
TMP_DIR="$(mktemp -d)"
DEBIAN_SNAPSHOT_MAIN_URL="http://snapshot.debian.org/archive/debian"
DEBIAN_SNAPSHOT_SECURITY_URL="http://snapshot.debian.org/archive/debian-security"
UBUNTU_SNAPSHOT_MAIN_URL="http://snapshot.ubuntu.com/ubuntu"
UBUNTU_SNAPSHOT_SECURITY_URL="http://snapshot.ubuntu.com/ubuntu"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ ! -f "$OS_LOCK_FILE" ]; then
  echo "Missing OS lockfile: $OS_LOCK_FILE"
  echo "Run make lock-os-image-host first."
  exit 1
fi

# shellcheck disable=SC1090
. "$OS_LOCK_FILE"

HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
  x86_64|amd64)
    LOCKED_IMAGE_HOST="${DEVCONTAINER_OS_IMAGE_AMD64:-}"
    ;;
  aarch64|arm64)
    LOCKED_IMAGE_HOST="${DEVCONTAINER_OS_IMAGE_ARM64:-}"
    ;;
  *)
    echo "Unsupported host architecture: $HOST_ARCH"
    exit 1
    ;;
esac

if [ -z "$LOCKED_IMAGE_HOST" ]; then
  echo "Missing locked OS image for host architecture in $OS_LOCK_FILE"
  exit 1
fi

OS_INFO="$(docker run --rm --entrypoint /bin/sh "$LOCKED_IMAGE_HOST" -lc '. /etc/os-release && printf "%s|%s" "${ID:-}" "${VERSION_CODENAME:-}"')"
DIST_ID="$(printf '%s' "$OS_INFO" | awk -F'|' '{print $1}')"
CODENAME="$(printf '%s' "$OS_INFO" | awk -F'|' '{print $2}')"
if [ -z "$DIST_ID" ] || [ -z "$CODENAME" ]; then
  echo "Unable to determine distro id/codename from image: $LOCKED_IMAGE_HOST"
  exit 1
fi

case "$DIST_ID" in
  debian)
    MAIN_BASE_URL="$DEBIAN_SNAPSHOT_MAIN_URL"
    SECURITY_BASE_URL="$DEBIAN_SNAPSHOT_SECURITY_URL"
    ;;
  ubuntu)
    MAIN_BASE_URL="$UBUNTU_SNAPSHOT_MAIN_URL"
    SECURITY_BASE_URL="$UBUNTU_SNAPSHOT_SECURITY_URL"
    ;;
  *)
    echo "Unsupported distro id for apt snapshot locking: $DIST_ID"
    exit 1
    ;;
esac

fetch_index_file() {
  base_url="$1"
  suite="$2"
  out_file="$3"
  if curl -fsSL "${base_url}/${SNAPSHOT_TS}/dists/${suite}/InRelease" -o "$out_file"; then
    return 0
  fi
  curl -fsSL "${base_url}/${SNAPSHOT_TS}/dists/${suite}/Release" -o "$out_file"
}

fetch_index_file "$MAIN_BASE_URL" "$CODENAME" "$TMP_DIR/main-index"
fetch_index_file "$MAIN_BASE_URL" "${CODENAME}-updates" "$TMP_DIR/updates-index"
fetch_index_file "$SECURITY_BASE_URL" "${CODENAME}-security" "$TMP_DIR/security-index"

MAIN_RELEASE_SHA256="$(sha256sum "$TMP_DIR/main-index" | awk '{print $1}')"
UPDATES_RELEASE_SHA256="$(sha256sum "$TMP_DIR/updates-index" | awk '{print $1}')"
SECURITY_RELEASE_SHA256="$(sha256sum "$TMP_DIR/security-index" | awk '{print $1}')"

mkdir -p "$LOCK_DIR"
{
  printf '# Created: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'APT_DIST_ID=%s\n' "$DIST_ID"
  printf 'APT_DIST_CODENAME=%s\n' "$CODENAME"
  printf 'APT_SNAPSHOT_TIMESTAMP=%s\n' "$SNAPSHOT_TS"
  printf 'APT_MAIN_BASE_URL=%s\n' "$MAIN_BASE_URL"
  printf 'APT_SECURITY_BASE_URL=%s\n' "$SECURITY_BASE_URL"
  printf 'APT_MAIN_RELEASE_SHA256=%s\n' "$MAIN_RELEASE_SHA256"
  printf 'APT_UPDATES_RELEASE_SHA256=%s\n' "$UPDATES_RELEASE_SHA256"
  printf 'APT_SECURITY_RELEASE_SHA256=%s\n' "$SECURITY_RELEASE_SHA256"
} >"$LOCK_FILE"

echo "Created ${LOCK_FILE}"

#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env-vars/.env"
LOCK_DIR="${ROOT_DIR}/os-environment"
LOCK_FILE="${LOCK_DIR}/os-lock.env"
SNAPSHOT_TS="$(date -u '+%Y%m%dT%H%M%SZ')"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

SOURCE_IMAGE="$(awk -F= '/^DEVCONTAINER_OS_IMAGE=/{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
if [ -z "$SOURCE_IMAGE" ]; then
  echo "DEVCONTAINER_OS_IMAGE is not set in $ENV_FILE"
  exit 1
fi

if printf '%s' "$SOURCE_IMAGE" | grep -q '@sha256:'; then
  LOCKED_IMAGE="$SOURCE_IMAGE"
else
  docker pull "$SOURCE_IMAGE" >/dev/null
  LOCKED_IMAGE="$(docker image inspect --format '{{index .RepoDigests 0}}' "$SOURCE_IMAGE" 2>/dev/null || true)"
  if [ -z "$LOCKED_IMAGE" ]; then
    echo "Failed to resolve digest for $SOURCE_IMAGE"
    exit 1
  fi
fi

OS_INFO="$(docker run --rm --entrypoint /bin/sh "$LOCKED_IMAGE" -lc '. /etc/os-release && printf "%s|%s" "${ID:-}" "${VERSION_CODENAME:-}"')"
DIST_ID="$(printf '%s' "$OS_INFO" | awk -F'|' '{print $1}')"
CODENAME="$(printf '%s' "$OS_INFO" | awk -F'|' '{print $2}')"
if [ -z "$DIST_ID" ] || [ -z "$CODENAME" ]; then
  echo "Unable to determine distro id/codename from image: $LOCKED_IMAGE"
  exit 1
fi

case "$DIST_ID" in
  debian)
    MAIN_BASE_URL="http://snapshot.debian.org/archive/debian"
    SECURITY_BASE_URL="http://snapshot.debian.org/archive/debian-security"
    ;;
  ubuntu)
    MAIN_BASE_URL="http://snapshot.ubuntu.com/ubuntu"
    SECURITY_BASE_URL="http://snapshot.ubuntu.com/ubuntu"
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
  printf '# Created: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf 'DEVCONTAINER_OS_IMAGE_SOURCE=%s\n' "$SOURCE_IMAGE"
  printf 'DEVCONTAINER_OS_IMAGE=%s\n' "$LOCKED_IMAGE"
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

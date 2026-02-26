#!/usr/bin/env sh
set -eu

LOCK_FILE="/tmp/os-environment/os-lock.env"

if [ "${DEV_ENV_LOCKED:-0}" != "1" ]; then
  exit 0
fi

if [ ! -f "$LOCK_FILE" ]; then
  echo "OS lockfile does not exist: $LOCK_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$LOCK_FILE"

if [ ! -f /etc/os-release ]; then
  echo "/etc/os-release is missing; cannot determine Debian codename."
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
DIST_ID="${ID:-}"
CODENAME="${VERSION_CODENAME:-}"
if [ -z "$DIST_ID" ] || [ -z "$CODENAME" ]; then
  echo "ID or VERSION_CODENAME is missing in /etc/os-release"
  exit 1
fi

LOCK_DIST_ID="${APT_DIST_ID:-}"
if [ -n "${LOCK_DIST_ID:-}" ] && [ "$LOCK_DIST_ID" != "$DIST_ID" ]; then
  echo "APT_DIST_ID mismatch. Lock: $LOCK_DIST_ID, image: $DIST_ID"
  exit 1
fi

LOCK_CODENAME="${APT_DIST_CODENAME:-${APT_DEBIAN_CODENAME:-}}"
if [ -n "${LOCK_CODENAME:-}" ] && [ "$LOCK_CODENAME" != "$CODENAME" ]; then
  echo "APT_DIST_CODENAME mismatch. Lock: $LOCK_CODENAME, image: $CODENAME"
  exit 1
fi

find_release_file() {
  pattern="$1"
  find /var/lib/apt/lists -type f -name "$pattern" | head -n 1
}

find_index_file() {
  suite="$1"
  inrelease_pattern="*_dists_${suite}_InRelease"
  release_pattern="*_dists_${suite}_Release"
  file_path="$(find_release_file "$inrelease_pattern")"
  if [ -n "$file_path" ]; then
    printf '%s' "$file_path"
    return 0
  fi
  find_release_file "$release_pattern"
}

verify_file_hash() {
  file_path="$1"
  expected_sha="$2"
  label="$3"

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    echo "Unable to find apt Release file for ${label}"
    exit 1
  fi
  if [ -z "$expected_sha" ]; then
    echo "Missing expected SHA for ${label} in $LOCK_FILE"
    exit 1
  fi

  actual_sha="$(sha256sum "$file_path" | awk '{print $1}')"
  if [ "$actual_sha" != "$expected_sha" ]; then
    echo "Apt snapshot hash mismatch for ${label}"
    echo "Expected: $expected_sha"
    echo "Actual:   $actual_sha"
    exit 1
  fi
}

MAIN_SHA="${APT_MAIN_RELEASE_SHA256:-${APT_DEBIAN_RELEASE_SHA256:-}}"
UPDATES_SHA="${APT_UPDATES_RELEASE_SHA256:-${APT_DEBIAN_UPDATES_RELEASE_SHA256:-}}"
SECURITY_SHA="${APT_SECURITY_RELEASE_SHA256:-${APT_DEBIAN_SECURITY_RELEASE_SHA256:-}}"

verify_file_hash "$(find_index_file "${CODENAME}")" "$MAIN_SHA" "apt/${CODENAME}"
verify_file_hash "$(find_index_file "${CODENAME}-updates")" "$UPDATES_SHA" "apt/${CODENAME}-updates"
verify_file_hash "$(find_index_file "${CODENAME}-security")" "$SECURITY_SHA" "apt/${CODENAME}-security"

echo "Verified apt snapshot Release hashes for ${DIST_ID}/${CODENAME}"

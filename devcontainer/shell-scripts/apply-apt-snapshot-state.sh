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

SNAPSHOT_TS="${APT_SNAPSHOT_TIMESTAMP:-}"
if [ -z "$SNAPSHOT_TS" ]; then
  echo "APT_SNAPSHOT_TIMESTAMP is missing in $LOCK_FILE"
  exit 1
fi

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
if [ -n "$LOCK_DIST_ID" ] && [ "$LOCK_DIST_ID" != "$DIST_ID" ]; then
  echo "APT_DIST_ID mismatch. Lock: $LOCK_DIST_ID, image: $DIST_ID"
  exit 1
fi

LOCK_CODENAME="${APT_DIST_CODENAME:-}"
if [ -n "$LOCK_CODENAME" ] && [ "$LOCK_CODENAME" != "$CODENAME" ]; then
  echo "APT_DIST_CODENAME mismatch. Lock: $LOCK_CODENAME, image: $CODENAME"
  exit 1
fi

MAIN_BASE_URL="${APT_MAIN_BASE_URL:-}"
SECURITY_BASE_URL="${APT_SECURITY_BASE_URL:-}"
if [ -z "$MAIN_BASE_URL" ] || [ -z "$SECURITY_BASE_URL" ]; then
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
      echo "Unsupported distro id for apt snapshot configuration: $DIST_ID"
      exit 1
      ;;
  esac
fi

rm -f /etc/apt/sources.list.d/*.sources
cat >/etc/apt/sources.list <<EOF
deb [check-valid-until=no] ${MAIN_BASE_URL}/${SNAPSHOT_TS} ${CODENAME} main
deb [check-valid-until=no] ${MAIN_BASE_URL}/${SNAPSHOT_TS} ${CODENAME}-updates main
deb [check-valid-until=no] ${SECURITY_BASE_URL}/${SNAPSHOT_TS} ${CODENAME}-security main
EOF

cat >/etc/apt/apt.conf.d/99snapshot <<EOF
Acquire::Check-Valid-Until "false";
EOF

echo "Configured apt snapshot for ${DIST_ID}/${CODENAME} at ${SNAPSHOT_TS}"

#!/usr/bin/env bash

set -e

echo ">>> Installing base system packages..."

PACKAGE_LIST_FILE="/tmp/base-binaries-environment/base-binaries.list"

if [ ! -f "$PACKAGE_LIST_FILE" ]; then
  echo "Base binaries list does not exist: $PACKAGE_LIST_FILE"
  exit 1
fi

apt-get update
/tmp/verify-apt-snapshot-state.sh

PACKAGES="$(awk '
  $0 !~ /^[[:space:]]*#/ && $0 !~ /^[[:space:]]*$/ {print}
' "$PACKAGE_LIST_FILE" | tr '\n' ' ')"

if [ -z "$PACKAGES" ]; then
  echo "No base binaries were defined in $PACKAGE_LIST_FILE"
  exit 1
fi

apt-get install -y $PACKAGES

apt-get clean
rm -rf /var/lib/apt/lists/*

echo ">>> Base software installation completed."

#!/usr/bin/env bash
set -euo pipefail

HOST_DATA_DIR_VALUE="${HOST_DATA_DIR:-}"
MOUNT_PATH="${HOST_DATA_MOUNT_PATH:-/home/dev/data_external}"
LINK_PATH="${HOST_DATA_SYMLINK_PATH:-/home/dev/dev_container/workspace/data_external}"
LINK_PARENT="$(dirname "$LINK_PATH")"

if [ -n "$HOST_DATA_DIR_VALUE" ]; then
  mkdir -p "$LINK_PARENT"
  if [ -d "$MOUNT_PATH" ]; then
    rm -rf "$LINK_PATH"
    ln -s "$MOUNT_PATH" "$LINK_PATH"
  else
    echo "HOST_DATA_DIR is set but mount path is missing: $MOUNT_PATH"
    rm -rf "$LINK_PATH"
  fi
else
  rm -rf "$LINK_PATH"
fi

exec "$@"

#!/usr/bin/env bash
set -euo pipefail

HOST_DATA_DIR_VALUE="${HOST_DATA_DIR:-}"
WORKSPACE_DIR="/home/dev/dev_container/workspace"
LINK_PATH="${WORKSPACE_DIR}/data_external"
MOUNT_PATH="/home/dev/data_external"

if [ -n "$HOST_DATA_DIR_VALUE" ]; then
  mkdir -p "$WORKSPACE_DIR"
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

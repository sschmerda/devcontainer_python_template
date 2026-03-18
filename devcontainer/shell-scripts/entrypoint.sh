#!/usr/bin/env bash
set -euo pipefail

. /usr/local/bin/export-runtime-env.sh

HOST_DATA_DIR_VALUE="${HOST_DATA_DIR:-}"

if [ -n "$HOST_DATA_DIR_VALUE" ]; then
  MOUNT_PATH="${HOST_DATA_MOUNT_PATH:?HOST_DATA_MOUNT_PATH is not set. Set it in devcontainer/env-vars/.env.runtime.}"
  LINK_PATH="${HOST_DATA_SYMLINK_PATH:?HOST_DATA_SYMLINK_PATH is not set. Set it in devcontainer/env-vars/.env.runtime.}"
  LINK_PARENT="$(dirname "$LINK_PATH")"
  mkdir -p "$LINK_PARENT"
  if [ -d "$MOUNT_PATH" ]; then
    rm -rf "$LINK_PATH"
    ln -s "$MOUNT_PATH" "$LINK_PATH"
  else
    echo "HOST_DATA_DIR is set but mount path is missing: $MOUNT_PATH"
    rm -rf "$LINK_PATH"
  fi
else
  if [ -n "${HOST_DATA_SYMLINK_PATH:-}" ]; then
    rm -rf "$HOST_DATA_SYMLINK_PATH"
  fi
fi

exec "$@"

#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ARCHIVE_DIR="/home/dev/dev_container/devcontainer/build-assets"
SETTINGS_DIR="$HOME/.jupyter/lab/user-settings"

mkdir -p "$ARCHIVE_DIR"

if [ ! -d "$SETTINGS_DIR" ]; then
  echo "No JupyterLab user settings found at $SETTINGS_DIR"
  exit 1
fi

tar -czf "$ARCHIVE_DIR/jupyterlab-user-settings.tar.gz" -C "$SETTINGS_DIR" .

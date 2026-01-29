#!/usr/bin/env sh
set -e

ARCHIVE=""
TARGET_DIR="$HOME/.jupyter/lab/user-settings"

# Prefer the repo archive if present (freshly exported inside the container),
# otherwise fall back to the image build-time copy.
REPO_ARCHIVE="/home/dev/dev_container/devcontainer/build_assets/jupyterlab-user-settings.tar.gz"
IMAGE_ARCHIVE="/tmp/build_assets/jupyterlab-user-settings.tar.gz"

if [ -f "$REPO_ARCHIVE" ]; then
  ARCHIVE="$REPO_ARCHIVE"
elif [ -f "$IMAGE_ARCHIVE" ]; then
  ARCHIVE="$IMAGE_ARCHIVE"
else
  echo "JupyterLab settings archive not found: $REPO_ARCHIVE or $IMAGE_ARCHIVE"
  exit 0
fi

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR"/*
tar -xzf "$ARCHIVE" -C "$TARGET_DIR"

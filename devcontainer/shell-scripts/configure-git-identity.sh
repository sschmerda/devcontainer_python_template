#!/usr/bin/env bash
set -euo pipefail

name="${GIT_USER_NAME:-}"
email="${GIT_USER_EMAIL:-}"

if [ -z "$name" ] && [ -z "$email" ]; then
  echo ">>> Skipping Git identity configuration (GIT_USER_NAME/GIT_USER_EMAIL unset)."
  exit 0
fi

if [ -z "$name" ] || [ -z "$email" ]; then
  echo ">>> Git identity configuration requires both GIT_USER_NAME and GIT_USER_EMAIL."
  exit 1
fi

echo ">>> Configuring Git identity..."
git config --global user.name "$name"
git config --global user.email "$email"
echo ">>> Git identity configured."

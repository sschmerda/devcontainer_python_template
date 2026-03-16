#!/usr/bin/env bash
set -e

echo ">>> Installing dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
LOCK_FILE="/tmp/dotfiles-environment/dotfiles-lock.env"
DOTFILES_LIST_FILE="/tmp/dotfiles-environment/dotfiles.list"

if [ -d "$DOTFILES_DIR" ]; then
  rm -rf "$DOTFILES_DIR"
fi

if [ ! -f "$DOTFILES_LIST_FILE" ]; then
  echo "Dotfiles list file does not exist: $DOTFILES_LIST_FILE"
  exit 1
fi

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ ! -f "$LOCK_FILE" ]; then
    echo "Dotfiles lockfile does not exist: $LOCK_FILE"
    exit 1
  fi
  # shellcheck disable=SC1090
  . "$LOCK_FILE"
  DOTFILES_REPO="${DOTFILES_REPO:-}"
  DOTFILES_REF="${DOTFILES_REF:-}"
  if [ -z "$DOTFILES_REPO" ] || [ -z "$DOTFILES_REF" ]; then
    echo "Dotfiles lockfile is missing required fields (DOTFILES_REPO/DOTFILES_REF): $LOCK_FILE"
    exit 1
  fi
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  cd "$DOTFILES_DIR"
  git checkout --detach "$DOTFILES_REF"
else
  : "${DOTFILES_REPO:?DOTFILES_REPO is not set. Set it in devcontainer/env-vars/.env.build.}"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  cd "$DOTFILES_DIR"
fi

# Deploy configured dotfiles using stow.
stow_packages="$(awk '
  /^[[:space:]]*#/ {next}
  /^[[:space:]]*$/ {next}
  {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print $0}
' "$DOTFILES_LIST_FILE" | tr '\n' ' ')"

if [ -z "$stow_packages" ]; then
  echo "No dotfiles packages enabled in: $DOTFILES_LIST_FILE"
  exit 1
fi

# shellcheck disable=SC2086
stow $stow_packages

# Remove Git metadata so the stow source stays available but cannot be committed/pulled.
rm -rf "$DOTFILES_DIR/.git"

echo ">>> Dotfiles installation completed."

#!/usr/bin/env bash
set -e

echo ">>> Installing dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
LOCK_FILE="/tmp/dotfiles-environment/dotfiles-lock.env"

if [ -d "$DOTFILES_DIR" ]; then
  rm -rf "$DOTFILES_DIR"
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

# Deploy dotfiles using stow
stow zsh tmux nvim

# Remove Git metadata so the stow source stays available but cannot be committed/pulled.
rm -rf "$DOTFILES_DIR/.git"

echo ">>> Dotfiles installation completed."

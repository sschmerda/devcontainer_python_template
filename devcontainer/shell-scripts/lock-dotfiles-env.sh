#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

LOCK_FILE="/home/dev/dev_container/devcontainer/dotfiles-environment/dotfiles-lock.env"
: "${DOTFILES_REPO:?DOTFILES_REPO is not set. Set it in devcontainer/env-vars/.env.}"

DOTFILES_REF="$(git ls-remote "$DOTFILES_REPO" HEAD | awk '{print $1}')"
if [ -z "${DOTFILES_REF:-}" ]; then
  echo "Unable to resolve HEAD commit for dotfiles repo: $DOTFILES_REPO"
  exit 1
fi

{
  printf '# Created: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'DOTFILES_REPO=%s\n' "$DOTFILES_REPO"
  printf 'DOTFILES_REF=%s\n' "$DOTFILES_REF"
} >"$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

LOCK_FILE="/home/dev/dev_container/devcontainer/additional-binaries-environment/tooling-config-lock.env"

OH_MY_ZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
TPM_REPO="https://github.com/tmux-plugins/tpm.git"

resolve_head_ref() {
  local repo
  repo="$1"
  git ls-remote "$repo" HEAD | awk '{print $1}'
}

OH_MY_ZSH_REF="$(resolve_head_ref "$OH_MY_ZSH_REPO")"
ZSH_AUTOSUGGESTIONS_REF="$(resolve_head_ref "$ZSH_AUTOSUGGESTIONS_REPO")"
ZSH_SYNTAX_HIGHLIGHTING_REF="$(resolve_head_ref "$ZSH_SYNTAX_HIGHLIGHTING_REPO")"
POWERLEVEL10K_REF="$(resolve_head_ref "$POWERLEVEL10K_REPO")"
TPM_REF="$(resolve_head_ref "$TPM_REPO")"

for ref_name in \
  OH_MY_ZSH_REF \
  ZSH_AUTOSUGGESTIONS_REF \
  ZSH_SYNTAX_HIGHLIGHTING_REF \
  POWERLEVEL10K_REF \
  TPM_REF; do
  if [ -z "${!ref_name}" ]; then
    echo "Unable to resolve HEAD commit for ${ref_name}"
    exit 1
  fi
done

tmp_file="$(mktemp)"
{
  printf '# Created: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf 'OH_MY_ZSH_REPO=%s\n' "$OH_MY_ZSH_REPO"
  printf 'OH_MY_ZSH_REF=%s\n' "$OH_MY_ZSH_REF"
  printf 'ZSH_AUTOSUGGESTIONS_REPO=%s\n' "$ZSH_AUTOSUGGESTIONS_REPO"
  printf 'ZSH_AUTOSUGGESTIONS_REF=%s\n' "$ZSH_AUTOSUGGESTIONS_REF"
  printf 'ZSH_SYNTAX_HIGHLIGHTING_REPO=%s\n' "$ZSH_SYNTAX_HIGHLIGHTING_REPO"
  printf 'ZSH_SYNTAX_HIGHLIGHTING_REF=%s\n' "$ZSH_SYNTAX_HIGHLIGHTING_REF"
  printf 'POWERLEVEL10K_REPO=%s\n' "$POWERLEVEL10K_REPO"
  printf 'POWERLEVEL10K_REF=%s\n' "$POWERLEVEL10K_REF"
  printf 'TPM_REPO=%s\n' "$TPM_REPO"
  printf 'TPM_REF=%s\n' "$TPM_REF"
} >"$tmp_file"
mv "$tmp_file" "$LOCK_FILE"

echo "Created lockfile: $LOCK_FILE"

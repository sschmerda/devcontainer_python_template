#!/usr/bin/env bash
set -euo pipefail

echo ">>> Configuring tooling..."

LOCK_FILE="/tmp/additional-binaries-environment/tooling-config-lock.env"

OH_MY_ZSH_REPO_DEFAULT="https://github.com/ohmyzsh/ohmyzsh.git"
ZSH_AUTOSUGGESTIONS_REPO_DEFAULT="https://github.com/zsh-users/zsh-autosuggestions.git"
ZSH_SYNTAX_HIGHLIGHTING_REPO_DEFAULT="https://github.com/zsh-users/zsh-syntax-highlighting.git"
POWERLEVEL10K_REPO_DEFAULT="https://github.com/romkatv/powerlevel10k.git"
TPM_REPO_DEFAULT="https://github.com/tmux-plugins/tpm.git"

require_var() {
  local name value
  name="$1"
  value="${!name:-}"
  if [ -z "$value" ]; then
    echo "Missing required lock value: $name"
    exit 1
  fi
  printf '%s' "$value"
}

clone_repo() {
  local repo target ref
  repo="$1"
  target="$2"
  ref="$3"

  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  if [ -n "$ref" ]; then
    git clone "$repo" "$target"
    git -C "$target" checkout -q "$ref"
  else
    git clone --depth=1 "$repo" "$target"
  fi
}

resolve_repo_and_ref() {
  local key default_repo repo ref
  key="$1"
  default_repo="$2"
  if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
    if [ ! -f "$LOCK_FILE" ]; then
      echo "User tooling lockfile does not exist: $LOCK_FILE"
      exit 1
    fi
    # shellcheck disable=SC1090
    . "$LOCK_FILE"
    repo="$(require_var "${key}_REPO")"
    ref="$(require_var "${key}_REF")"
  else
    repo="$default_repo"
    ref=""
  fi
  printf '%s|%s\n' "$repo" "$ref"
}

ohmyzsh_spec="$(resolve_repo_and_ref OH_MY_ZSH "$OH_MY_ZSH_REPO_DEFAULT")"
zsh_autosuggestions_spec="$(resolve_repo_and_ref ZSH_AUTOSUGGESTIONS "$ZSH_AUTOSUGGESTIONS_REPO_DEFAULT")"
zsh_syntax_highlighting_spec="$(resolve_repo_and_ref ZSH_SYNTAX_HIGHLIGHTING "$ZSH_SYNTAX_HIGHLIGHTING_REPO_DEFAULT")"
powerlevel10k_spec="$(resolve_repo_and_ref POWERLEVEL10K "$POWERLEVEL10K_REPO_DEFAULT")"
tpm_spec="$(resolve_repo_and_ref TPM "$TPM_REPO_DEFAULT")"

clone_repo "${ohmyzsh_spec%%|*}" "$HOME/.oh-my-zsh" "${ohmyzsh_spec#*|}"

zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_repo "${zsh_autosuggestions_spec%%|*}" "$zsh_custom_dir/plugins/zsh-autosuggestions" "${zsh_autosuggestions_spec#*|}"
clone_repo "${zsh_syntax_highlighting_spec%%|*}" "$zsh_custom_dir/plugins/zsh-syntax-highlighting" "${zsh_syntax_highlighting_spec#*|}"
clone_repo "${powerlevel10k_spec%%|*}" "$zsh_custom_dir/themes/powerlevel10k" "${powerlevel10k_spec#*|}"

# -------------------------
# tmux
# -------------------------
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
clone_repo "${tpm_spec%%|*}" "$TMUX_PLUGIN_MANAGER_PATH/tpm" "${tpm_spec#*|}"
chmod +x "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins"
"$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins"

echo ">>> Tooling configuration completed."

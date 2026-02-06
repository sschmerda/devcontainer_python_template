#!/usr/bin/env bash
set -e

echo ">>> Installing additional user packages..."

# -------------------------
# TinyTeX (latest via R)
# -------------------------
sh /tmp/install-tinytex.sh

# Ensure TinyTeX binaries are on PATH for common shells
if ! grep -q '/home/dev/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.profile"
fi
if ! grep -q '/home/dev/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.zshrc"
fi

# -------------------------
# oh-my-zsh
# -------------------------
export KEEP_ZSHRC=yes
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# oh-my-zsh plugins
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# -------------------------
# tmux
# -------------------------
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
git clone --depth=1 https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_MANAGER_PATH/tpm"
chmod +x "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins"
"$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins"

# -------------------------
# nvim + lazyvim
# -------------------------
nvim --headless +'Lazy! sync' +qa

echo ">>> Additional user software installation completed."

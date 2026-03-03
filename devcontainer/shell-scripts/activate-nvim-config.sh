#!/usr/bin/env bash
set -euo pipefail

echo ">>> Activating Neovim config..."

if ! command -v nvim >/dev/null 2>&1; then
  echo "nvim not found in PATH."
  exit 1
fi

if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
  echo "Missing Neovim config: $HOME/.config/nvim/init.lua"
  exit 1
fi

nvim --headless +'Lazy! sync' +qa
echo ">>> Skipping Mason/Treesitter prewarm in image build (handled at first editor start)."

echo ">>> Neovim config activation completed."

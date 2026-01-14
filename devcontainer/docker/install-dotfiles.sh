#!/usr/bin/env bash
set -e

echo ">>> Installing dotfiles..."

# Clone your dotfiles repo
git clone https://github.com/sschmerda/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"

# Deploy dotfiles using stow
stow zsh tmux nvim

echo ">>> Dotfiles installation completed."

#!/usr/bin/env bash
set -e

echo ">>> Installing dotfiles..."

# Clone your dotfiles repo
git clone https://github.com/sschmerda/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"

# Deploy dotfiles using stow
stow zsh tmux nvim

# Remove Git metadata so the stow source stays available but cannot be committed/pulled.
rm -rf "$HOME/dotfiles/.git"

echo ">>> Dotfiles installation completed."

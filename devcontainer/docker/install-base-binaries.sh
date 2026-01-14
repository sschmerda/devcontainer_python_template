#!/usr/bin/env bash

set -e

echo ">>> Installing base system packages..."

# fzf, neovim is missing
apt-get update &&
  apt-get install -y \
    zsh \
    tmux \
    fd-find \
    git \
    stow \
    curl \
    wget \
    ripgrep \
    fd-find \
    ncurses-bin \
    ncurses-term \
    build-essential \
    locales \
    ca-certificates \
    tzdata \
    fastfetch \
    lazygit \
    btop \
    bat \
    sudo &&
  apt-get clean &&
  rm -rf /var/lib/apt/lists/*

echo ">>> Base software installation completed."

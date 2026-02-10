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
    make \
    ripgrep \
    bzip2 \
    libfontconfig1 \
    libfreetype6 \
    fonts-dejavu-core \
    ncurses-bin \
    ncurses-term \
    fastfetch \
    lazygit \
    btop \
    bat \
    sudo &&
  apt-get clean &&
  rm -rf /var/lib/apt/lists/*

echo ">>> Base software installation completed."

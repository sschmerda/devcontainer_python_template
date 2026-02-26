#!/usr/bin/env bash

set -e

echo ">>> Installing base system packages..."

# fzf, neovim is missing
apt-get update
/tmp/verify-apt-snapshot-state.sh

apt-get install -y \
    zsh \
    tmux \
    fd-find \
    git \
    stow \
    curl \
    wget \
    make \
    gcc \
    g++ \
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
    sudo

apt-get clean
rm -rf /var/lib/apt/lists/*

echo ">>> Base software installation completed."

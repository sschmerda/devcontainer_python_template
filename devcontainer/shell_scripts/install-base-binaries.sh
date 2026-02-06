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
    perl \
    build-essential \
    pkg-config \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libtiff-dev \
    libjpeg-dev \
    libwebp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libnode-dev \
    libicu-dev \
    libx11-dev \
    libxml2-dev \
    libssl-dev \
    pandoc \
    zlib1g-dev \
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

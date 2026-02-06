#!/usr/bin/env bash
set -e
ARCH=$(uname -m)

echo ">>> Installing additional system packages..."

# -------------------------
# fzf
# -------------------------
FZF_VERSION="0.67.0"

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  FZF_TAR="fzf-${FZF_VERSION}-linux_amd64.tar.gz"
elif [ "$ARCH" = "aarch64" ]; then
  FZF_TAR="fzf-${FZF_VERSION}-linux_arm64.tar.gz"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

curl -Lo /tmp/$FZF_TAR \
  "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/${FZF_TAR}"

tar -xzf /tmp/$FZF_TAR -C /usr/local/bin
chmod +x /usr/local/bin/fzf
rm /tmp/$FZF_TAR

# -------------------------
# nvim + lazyvim
# -------------------------
NEOVIM_VERSION="0.11.5"

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  NVIM_TAR="nvim-linux-x86_64.tar.gz"
elif [ "$ARCH" = "aarch64" ]; then
  NVIM_TAR="nvim-linux-arm64.tar.gz"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

curl -Lo /tmp/$NVIM_TAR \
  "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${NVIM_TAR}"

cd /tmp

# Ensure /usr/local exists
mkdir -p /usr/local
tar -xzf /tmp/"$NVIM_TAR" -C /usr/local
ln -sf /usr/local/nvim-linux*/bin/nvim /usr/local/bin/nvim

rm /tmp/$NVIM_TAR

# -------------------------
# lsd
# -------------------------
LSD_VERSION="1.2.0"

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  LSD_ASSET="lsd-musl_${LSD_VERSION}_amd64.deb"
elif [ "$ARCH" = "aarch64" ]; then
  LSD_ASSET="lsd-musl_${LSD_VERSION}_arm64.deb"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

curl -Lo /tmp/$LSD_ASSET \
  https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/$LSD_ASSET

dpkg -i /tmp/$LSD_ASSET
rm /tmp/$LSD_ASSET

echo ">>> Additional system software installation completed."

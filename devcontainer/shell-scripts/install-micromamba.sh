#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
WORKDIR="$(mktemp -d)"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

echo ">>> Installing micromamba..."

if [ "$ARCH" = "x86_64" ]; then
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C "$WORKDIR" bin/micromamba
elif [ "$ARCH" = "aarch64" ]; then
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xvj -C "$WORKDIR" bin/micromamba
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"
export MAMBA_CHANNEL_ALIAS="https://conda.anaconda.org"
mv "$WORKDIR/bin/micromamba" "$BIN_DIR/micromamba"
rm -rf "$WORKDIR"

echo ">>> Micromamba installation completed."

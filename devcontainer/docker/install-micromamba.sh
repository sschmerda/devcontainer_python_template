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
mv "$WORKDIR/bin/micromamba" "$BIN_DIR/micromamba"
rm -rf "$WORKDIR"

echo ">>> Creating micromamba environment..."
ENV_FILE="${MAMBA_ENV_FILE:-/tmp/environment.yml}"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing micromamba environment file: $ENV_FILE"
  exit 1
fi
micromamba create -y -f "$ENV_FILE"
micromamba clean --all --yes

ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  if ! grep -q "micromamba shell hook" "$ZSHRC"; then
    {
      echo ""
      echo "# Micromamba init (auto activation)"
      echo "if command -v micromamba >/dev/null 2>&1; then"
      echo "  eval \"\$(micromamba shell hook --shell zsh)\""
      echo "  micromamba activate dev"
      echo "fi"
    } >>"$ZSHRC"
  fi
fi

echo ">>> Micromamba installation completed."

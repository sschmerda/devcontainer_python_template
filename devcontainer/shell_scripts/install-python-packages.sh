#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

echo ">>> Creating micromamba environment..."
ENV_FILE="${MAMBA_ENV_FILE:-/tmp/environment.yml}"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing micromamba environment file: $ENV_FILE"
  exit 1
fi
case "$ENV_FILE" in
  *conda-lock.yml)
    echo ">>> Installing conda-lock (temporary env)..."
    micromamba create -y -n locktools -c conda-forge conda-lock
    micromamba run -n locktools conda-lock install \
      --prefix "$MAMBA_ROOT_PREFIX/envs/dev" \
      --micromamba \
      "$ENV_FILE"
    micromamba env remove -n locktools -y
    ;;
  *)
    micromamba create -y -n dev -f "$ENV_FILE"
    ;;
esac
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

echo ">>> Micromamba environment installation completed."

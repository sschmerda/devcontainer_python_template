#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

ENV_FILE="/tmp/mamba_environment/conda-lock.yml"
FALLBACK_ENV="/tmp/mamba_environment/environment.yml"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$FALLBACK_ENV" ]; then
    echo "Mamba lockfile not found: $ENV_FILE"
    echo "Falling back to latest env: $FALLBACK_ENV"
    micromamba create -y -n dev -f "$FALLBACK_ENV"
    micromamba clean --all --yes
  else
    echo "Missing micromamba environment file: $ENV_FILE"
    echo "No environment file found; skipping Python environment install."
    exit 0
  fi
else
  echo ">>> Installing conda-lock (temporary env)..."
  micromamba create -y -n locktools -c conda-forge conda-lock
  micromamba run -n locktools conda-lock install \
    --prefix "$MAMBA_ROOT_PREFIX/envs/dev" \
    --micromamba \
    "$ENV_FILE"
  micromamba env remove -n locktools -y
  micromamba clean --all --yes
fi

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

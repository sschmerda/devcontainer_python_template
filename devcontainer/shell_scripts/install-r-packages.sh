#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

echo ">>> Creating R micromamba environment..."
ENV_FILE="/tmp/r-environment/environment.yml"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing R environment file: $ENV_FILE"
  echo "No environment file found; skipping R environment install."
  exit 0
fi

micromamba create -y -n r-env -f "$ENV_FILE"
micromamba clean --all --yes

echo ">>> R micromamba environment installation completed."

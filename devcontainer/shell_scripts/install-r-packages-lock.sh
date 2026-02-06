#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

LOCK_FILE="/tmp/r-environment/conda-lock.yml"
FALLBACK_ENV="/tmp/r-environment/environment.yml"

if [ ! -f "$LOCK_FILE" ]; then
  if [ -f "$FALLBACK_ENV" ]; then
    echo "R lockfile not found: $LOCK_FILE"
    echo "Falling back to latest env: $FALLBACK_ENV"
    micromamba create -y -n r-env -f "$FALLBACK_ENV"
    micromamba clean --all --yes
  else
    echo "Missing R lockfile: $LOCK_FILE"
    echo "No environment file found; skipping R environment install."
    exit 0
  fi
else
  echo ">>> Installing conda-lock (temporary env)..."
  micromamba create -y -n locktools -c conda-forge conda-lock
  micromamba run -n locktools conda-lock install \
    --prefix "$MAMBA_ROOT_PREFIX/envs/r-env" \
    --micromamba \
    "$LOCK_FILE"
  micromamba env remove -n locktools -y
  micromamba clean --all --yes
fi

echo ">>> R micromamba environment installation completed."

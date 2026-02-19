#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

run_with_retries() {
  local max_attempts="${RETRY_ATTEMPTS:-4}"
  local base_delay="${RETRY_DELAY_SECONDS:-10}"
  local attempt=1

  while true; do
    if "$@"; then
      return 0
    fi

    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Command failed after ${max_attempts} attempts: $*"
      return 1
    fi

    echo "Command failed (attempt ${attempt}/${max_attempts}): $*"
    sleep $((base_delay * attempt))
    attempt=$((attempt + 1))
  done
}

LOCK_FILE="/tmp/r-environment/r-environment-lock.yml"
FALLBACK_ENV="/tmp/r-environment/r-environment.yml"

if [ ! -f "$LOCK_FILE" ]; then
  if [ -f "$FALLBACK_ENV" ]; then
    echo "R lockfile not found: $LOCK_FILE"
    echo "Falling back to latest env: $FALLBACK_ENV"
    run_with_retries micromamba env create -y -n r-env -f "$FALLBACK_ENV"
    micromamba clean --all --yes --force-pkgs-dirs
  else
    echo "Missing R lockfile: $LOCK_FILE"
    echo "No environment file found; skipping R environment install."
    exit 0
  fi
else
  echo ">>> Installing conda-lock (temporary env)..."
  run_with_retries micromamba create -y -n locktools -c conda-forge conda-lock
  run_with_retries micromamba run -n locktools conda-lock install \
    --prefix "$MAMBA_ROOT_PREFIX/envs/r-env" \
    --micromamba \
    "$LOCK_FILE"
  micromamba env remove -n locktools -y
  micromamba clean --all --yes --force-pkgs-dirs
fi

echo ">>> R micromamba environment installation completed."

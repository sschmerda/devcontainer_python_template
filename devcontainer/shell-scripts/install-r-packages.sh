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

echo ">>> Creating R micromamba environment..."
ENV_FILE="/tmp/r-environment/r-environment.yml"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing R environment file: $ENV_FILE"
  echo "No environment file found; skipping R environment install."
  exit 0
fi

run_with_retries micromamba env create -y -n r-env -f "$ENV_FILE"
micromamba clean --all --yes --force-pkgs-dirs

echo ">>> R micromamba environment installation completed."

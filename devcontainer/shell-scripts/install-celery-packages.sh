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

LOCK_FILE="/tmp/python-environment/python-environment-lock.yml"
ENV_FILE="/tmp/python-environment/python-environment.yml"

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ ! -s "$LOCK_FILE" ]; then
    echo "Missing Python lockfile: $LOCK_FILE"
    exit 1
  fi
  run_with_retries micromamba env create -y -n python-env -f "$LOCK_FILE"
else
  if [ ! -s "$ENV_FILE" ]; then
    echo "Missing Python environment file: $ENV_FILE"
    exit 1
  fi
  run_with_retries micromamba env create -y -n python-env -f "$ENV_FILE"
fi

micromamba clean --all --yes --force-pkgs-dirs


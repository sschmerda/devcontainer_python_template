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
LOCK_FILE="/tmp/r-environment/r-environment-lock.yml"
ENV_FILE="/tmp/r-environment/r-environment.yml"
RENDERED_ENV_FILE="$(mktemp /tmp/r-env-rendered.XXXXXX.yml)"
cleanup() {
  rm -f "$RENDERED_ENV_FILE"
}
trap cleanup EXIT

render_env_file() {
  : "${R_BASE_VERSION:?R_BASE_VERSION is not set. Set it in devcontainer/env-vars/.env.build.}"
  sed "s|__R_BASE_VERSION__|${R_BASE_VERSION}|g" "$ENV_FILE" \
    | awk '
        /^platforms:[[:space:]]*$/ {skip=1; next}
        skip && /^[^[:space:]]/ {skip=0}
        skip {next}
        {print}
      ' >"$RENDERED_ENV_FILE"
}

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ ! -f "$LOCK_FILE" ]; then
    echo "R lockfile does not exist: $LOCK_FILE"
    exit 1
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
else
  if [ ! -f "$ENV_FILE" ]; then
    echo "R environment file does not exist: $ENV_FILE"
    exit 1
  fi
  render_env_file
  run_with_retries micromamba env create -y -n r-env -f "$RENDERED_ENV_FILE"
  micromamba clean --all --yes --force-pkgs-dirs
fi

echo ">>> R micromamba environment installation completed."

#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

run_with_retries() {
  local max_attempts="${RETRY_ATTEMPTS:?RETRY_ATTEMPTS is not set. Set it in devcontainer/env-vars/.env.build.}"
  local base_delay="${RETRY_DELAY_SECONDS:?RETRY_DELAY_SECONDS is not set. Set it in devcontainer/env-vars/.env.build.}"
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
RENDERED_ENV_FILE="$(mktemp /tmp/python-env-rendered.XXXXXX.yml)"
cleanup() {
  rm -f "$RENDERED_ENV_FILE"
}
trap cleanup EXIT

render_env_file() {
  : "${PYTHON_VERSION:?PYTHON_VERSION is not set. Set it in devcontainer/env-vars/.env.build.}"
  sed "s|__PYTHON_VERSION__|${PYTHON_VERSION}|g" "$ENV_FILE" \
    | awk '
        /^platforms:[[:space:]]*$/ {skip=1; next}
        skip && /^[^[:space:]]/ {skip=0}
        skip {next}
        {print}
      ' >"$RENDERED_ENV_FILE"
}

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ ! -f "$LOCK_FILE" ]; then
    echo "Python lockfile does not exist: $LOCK_FILE"
    exit 1
  else
    echo ">>> Installing conda-lock (temporary env)..."
    run_with_retries micromamba create -y -n locktools -c conda-forge conda-lock
    run_with_retries micromamba run -n locktools conda-lock install \
      --prefix "$MAMBA_ROOT_PREFIX/envs/python-env" \
      --micromamba \
      "$LOCK_FILE"
    micromamba env remove -n locktools -y
    micromamba clean --all --yes --force-pkgs-dirs
  fi
else
  echo ">>> Creating micromamba environment..."
  if [ ! -f "$ENV_FILE" ]; then
    echo "Python environment file does not exist: $ENV_FILE"
    exit 1
  fi
  render_env_file
  run_with_retries micromamba env create -y -n python-env -f "$RENDERED_ENV_FILE"
  micromamba clean --all --yes --force-pkgs-dirs
fi

echo ">>> Micromamba environment installation completed."

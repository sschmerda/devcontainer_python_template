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
  run_with_retries micromamba env create -y -n python-env -f "$ENV_FILE"
  micromamba clean --all --yes --force-pkgs-dirs
fi

ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  if ! grep -q "micromamba shell hook" "$ZSHRC"; then
    {
      echo ""
      echo "# Micromamba init (auto activation)"
      echo "if command -v micromamba >/dev/null 2>&1; then"
      echo "  eval \"\$(micromamba shell hook --shell zsh)\""
      echo "  micromamba activate python-env"
      echo "fi"
    } >>"$ZSHRC"
  fi
fi

echo ">>> Micromamba environment installation completed."

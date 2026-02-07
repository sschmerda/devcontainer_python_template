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

echo ">>> Creating micromamba environment..."
ENV_FILE="/tmp/mamba_environment/environment.yml"
if [ ! -f "$ENV_FILE" ]; then
  FALLBACK_ENV="/tmp/mamba_environment/environment.yml"
  if [ -f "$FALLBACK_ENV" ]; then
    echo "Missing micromamba environment file: $ENV_FILE"
    echo "Falling back to: $FALLBACK_ENV"
    ENV_FILE="$FALLBACK_ENV"
  else
    echo "Missing micromamba environment file: $ENV_FILE"
    echo "No environment file found; skipping Python environment install."
    exit 0
  fi
fi
case "$ENV_FILE" in
  *conda-lock.yml)
    echo ">>> Installing conda-lock (temporary env)..."
    run_with_retries micromamba create -y -n locktools -c conda-forge conda-lock
    run_with_retries micromamba run -n locktools conda-lock install \
      --prefix "$MAMBA_ROOT_PREFIX/envs/python-env" \
      --micromamba \
      "$ENV_FILE"
    micromamba env remove -n locktools -y
    ;;
  *)
    run_with_retries micromamba create -y -n python-env -f "$ENV_FILE"
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
      echo "  micromamba activate python-env"
      echo "fi"
    } >>"$ZSHRC"
  fi
fi

echo ">>> Micromamba environment installation completed."

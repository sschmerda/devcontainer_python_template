#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/services-environment/flower"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"
: "${CONDA_LOCK_VERSION:?CONDA_LOCK_VERSION is not set. Set it in devcontainer/env-vars/.env.}"
: "${FLOWER_PYTHON_VERSION:?FLOWER_PYTHON_VERSION is not set. Set it in devcontainer/env-vars/.env.}"

ts="$(date "+%Y-%m-%d %H:%M:%S %Z")"
cd "$ENV_DIR"
rm -f flower-environment-lock.yml
RENDERED_ENV_FILE="$(mktemp /tmp/flower-env-lock-input.XXXXXX.yml)"
cleanup() {
  rm -f "$RENDERED_ENV_FILE"
}
trap cleanup EXIT
sed "s|__FLOWER_PYTHON_VERSION__|${FLOWER_PYTHON_VERSION}|g" flower-environment.yml >"$RENDERED_ENV_FILE"

if ! command -v conda-lock >/dev/null 2>&1; then
  micromamba create -y -n locktools -c conda-forge "conda-lock=${CONDA_LOCK_VERSION}"
  micromamba run -n locktools conda-lock lock -f "$RENDERED_ENV_FILE" --platform linux-64 --platform linux-aarch64 --lockfile flower-environment-lock.yml
  micromamba env remove -n locktools -y
  micromamba clean --all --yes >/dev/null 2>&1 || true
else
  conda-lock lock -f "$RENDERED_ENV_FILE" --platform linux-64 --platform linux-aarch64 --lockfile flower-environment-lock.yml
fi

micromamba clean --all --yes >/dev/null 2>&1 || true

tmp="$(mktemp)"
printf '# Created: %s\n' "$ts" >"$tmp"
cat flower-environment-lock.yml >>"$tmp"
mv "$tmp" flower-environment-lock.yml

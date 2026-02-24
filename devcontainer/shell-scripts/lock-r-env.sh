#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/r-environment"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"
: "${CONDA_LOCK_VERSION:?CONDA_LOCK_VERSION is not set. Set it in devcontainer/env-vars/.env.}"

ts="$(date "+%Y-%m-%d %H:%M:%S %Z")"
cd "$ENV_DIR"
rm -f r-environment-lock.yml

if ! command -v conda-lock >/dev/null 2>&1; then
  micromamba create -y -n locktools -c conda-forge "conda-lock=${CONDA_LOCK_VERSION}"
  micromamba run -n locktools conda-lock lock -f r-environment.yml --platform linux-64 --platform linux-aarch64 --lockfile r-environment-lock.yml
  micromamba env remove -n locktools -y
  micromamba clean --all --yes >/dev/null 2>&1 || true
else
  conda-lock lock -f r-environment.yml --platform linux-64 --platform linux-aarch64 --lockfile r-environment-lock.yml
fi

micromamba clean --all --yes >/dev/null 2>&1 || true

tmp="$(mktemp)"
printf '# Created: %s\n' "$ts" >"$tmp"
cat r-environment-lock.yml >>"$tmp"
mv "$tmp" r-environment-lock.yml

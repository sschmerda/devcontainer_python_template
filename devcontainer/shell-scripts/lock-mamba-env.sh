#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/python-environment"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

ts="$(date "+%Y-%m-%d %H:%M:%S %Z")"
cd "$ENV_DIR"
rm -f python-environment-lock.yml

if ! command -v conda-lock >/dev/null 2>&1; then
  micromamba create -y -n locktools -c conda-forge conda-lock=4.0.0
  micromamba run -n locktools conda-lock lock -f python-environment.yml --platform linux-64 --platform linux-aarch64 --lockfile python-environment-lock.yml
  micromamba env remove -n locktools -y
  micromamba clean --all --yes >/dev/null 2>&1 || true
else
  conda-lock lock -f python-environment.yml --platform linux-64 --platform linux-aarch64 --lockfile python-environment-lock.yml
fi

micromamba clean --all --yes >/dev/null 2>&1 || true

tmp="$(mktemp)"
printf '# Created: %s\n' "$ts" >"$tmp"
cat python-environment-lock.yml >>"$tmp"
mv "$tmp" python-environment-lock.yml

#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

ENV_DIR="/home/dev/dev_container/devcontainer/r-environment"
ROOT_DIR="/home/dev/dev_container/devcontainer"
BUILD_ENV_FILE="${ROOT_DIR}/env-vars/.env.build"
BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"

# shellcheck disable=SC1091
. "${ROOT_DIR}/shell-scripts/env-file-utils.sh"
export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"
set_env_from_file_if_unset "$BUILD_ENV_FILE" CONDA_LOCK_VERSION
set_env_from_file_if_unset "$BUILD_ENV_FILE" R_BASE_VERSION
: "${CONDA_LOCK_VERSION:?CONDA_LOCK_VERSION is not set. Set it in devcontainer/env-vars/.env.build.}"
: "${R_BASE_VERSION:?R_BASE_VERSION is not set. Set it in devcontainer/env-vars/.env.build.}"

ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
cd "$ENV_DIR"
rm -f r-environment-lock.yml
RENDERED_ENV_FILE="$(mktemp /tmp/r-env-lock-input.XXXXXX.yml)"
cleanup() {
  rm -f "$RENDERED_ENV_FILE"
}
trap cleanup EXIT
sed "s|__R_BASE_VERSION__|${R_BASE_VERSION}|g" r-environment.yml >"$RENDERED_ENV_FILE"

if ! command -v conda-lock >/dev/null 2>&1; then
  micromamba create -y -n locktools -c conda-forge "conda-lock=${CONDA_LOCK_VERSION}"
  micromamba run -n locktools conda-lock lock -f "$RENDERED_ENV_FILE" --platform linux-64 --platform linux-aarch64 --lockfile r-environment-lock.yml
  micromamba env remove -n locktools -y
  micromamba clean --all --yes >/dev/null 2>&1 || true
else
  conda-lock lock -f "$RENDERED_ENV_FILE" --platform linux-64 --platform linux-aarch64 --lockfile r-environment-lock.yml
fi

micromamba clean --all --yes >/dev/null 2>&1 || true

tmp="$(mktemp)"
printf '# Created: %s\n' "$ts" >"$tmp"
cat r-environment-lock.yml >>"$tmp"
mv "$tmp" r-environment-lock.yml

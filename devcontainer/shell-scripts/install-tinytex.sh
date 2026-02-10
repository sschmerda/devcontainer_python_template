#!/usr/bin/env bash
set -e

echo ">>> Installing TinyTeX via R..."

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"
export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

if ! command -v micromamba >/dev/null 2>&1; then
  echo "micromamba not found on PATH"
  exit 1
fi

INSTALLER_ENV="tinytex-installer"
cleanup_installer_env() {
  micromamba env remove -n "$INSTALLER_ENV" -y >/dev/null 2>&1 || true
  micromamba clean --all --yes >/dev/null 2>&1 || true
}
trap cleanup_installer_env EXIT

# Recreate the installer env every time to avoid stale state.
cleanup_installer_env
micromamba create -y -n "$INSTALLER_ENV" -c conda-forge r-base=4.5 r-tinytex

TEXLIVE_REPO_FILE="/tmp/latex-environment/latex-environment-lock.txt"
LOCKED_REPO_URL=""
if [ "${DEV_ENV_LOCKED:-0}" = "1" ] && [ -f "$TEXLIVE_REPO_FILE" ]; then
  LOCKED_REPO_URL="$(awk -F= '/^repo=/{print $2}' "$TEXLIVE_REPO_FILE" | head -n 1)"
fi

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  if [ -z "$LOCKED_REPO_URL" ]; then
    echo "DEV_ENV_LOCKED=1 but no locked TeX Live repository was found in ${TEXLIVE_REPO_FILE}"
    exit 1
  fi
  echo ">>> Installing TinyTeX from locked repository: ${LOCKED_REPO_URL}"
  micromamba run -n "$INSTALLER_ENV" Rscript -e "tinytex::install_tinytex(force = TRUE, dir = '${HOME}/.TinyTeX', version = '', bundle = 'TinyTeX-1', repo = '${LOCKED_REPO_URL}', add_path = TRUE)"
else
  echo ">>> Installing TinyTeX from default upstream repository (unpinned)."
  micromamba run -n "$INSTALLER_ENV" Rscript -e "tinytex::install_tinytex(force = TRUE, dir = '${HOME}/.TinyTeX', version = '', bundle = 'TinyTeX-1', add_path = TRUE)"
fi

# Ensure TinyTeX binaries are on PATH for common shells.
if ! grep -q '/home/dev/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.profile"
fi
if ! grep -q '/home/dev/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.zshrc"
fi

# Remove legacy user-library tinytex package from earlier builds.
rm -rf "${HOME}/.local/lib/R/library/tinytex"

# Final cleanup for this layer.
micromamba clean --all --yes >/dev/null 2>&1 || true

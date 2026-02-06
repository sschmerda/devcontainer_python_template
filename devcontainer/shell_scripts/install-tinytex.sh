#!/usr/bin/env bash
set -e

echo ">>> Installing TinyTeX (frozen release) via R..."

BIN_DIR="$HOME/.local/bin"
ROOT_PREFIX="$HOME/.local/share/mamba"
export PATH="$BIN_DIR:$PATH"
export MAMBA_ROOT_PREFIX="$ROOT_PREFIX"

curl_time() {
  local url="$1"
  curl -fsSIL --connect-timeout 4 --max-time 8 -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || return 1
}

if ! command -v micromamba >/dev/null 2>&1; then
  echo "micromamba not found on PATH"
  exit 1
fi

if ! micromamba env list | awk '{print $1}' | grep -qx "r-env"; then
  echo "r-env micromamba environment not found."
  exit 1
fi

R_LIBS_USER="${HOME}/.local/lib/R/library"
mkdir -p "$R_LIBS_USER"
micromamba run -n r-env Rscript -e "install.packages('tinytex', repos='https://cloud.r-project.org', lib='${R_LIBS_USER}')"

TEXLIVE_REPO_FILE="/tmp/latex-environment/texlive-repo.txt"
LOCKED_REPO_URL=""
if [ "${DEV_ENV_LOCKED:-0}" = "1" ] && [ -f "$TEXLIVE_REPO_FILE" ]; then
  LOCKED_REPO_URL="$(awk -F= '/^repo=/{print $2}' "$TEXLIVE_REPO_FILE" | head -n 1)"
fi

CURRENT_YEAR="$(date -u +%Y)"
FROZEN_BASES="
https://ftp.math.utah.edu/pub/tex/historic/systems/texlive
https://ftp.tug.org/historic/systems/texlive
https://ftp.tu-chemnitz.de/pub/tug/texlive/historic/systems/texlive
"
REPO_URL=""
YEAR_OFFSET=1
MAX_YEARS_BACK=30
while [ "$YEAR_OFFSET" -le "$MAX_YEARS_BACK" ]; do
  FROZEN_YEAR=$((CURRENT_YEAR - YEAR_OFFSET))
  BEST_REPO_URL=""
  BEST_TIME="9999"
  for BASE in $FROZEN_BASES; do
    MIRROR="${BASE}/${FROZEN_YEAR}/tlnet-final"
    TLPDB_URL="${MIRROR}/tlpkg/texlive.tlpdb"
    TLPDB_XZ_URL="${MIRROR}/tlpkg/texlive.tlpdb.xz"
    PROBE_URL=""
    if curl -fsI "$TLPDB_URL" >/dev/null 2>&1; then
      PROBE_URL="$TLPDB_URL"
    elif curl -fsI "$TLPDB_XZ_URL" >/dev/null 2>&1; then
      PROBE_URL="$TLPDB_XZ_URL"
    fi

    if [ -n "$PROBE_URL" ]; then
      TIME_TOTAL="$(curl_time "$PROBE_URL" || true)"
      if [ -n "$TIME_TOTAL" ] && awk -v t="$TIME_TOTAL" -v b="$BEST_TIME" 'BEGIN { exit !(t < b) }'; then
        BEST_TIME="$TIME_TOTAL"
        BEST_REPO_URL="$MIRROR"
      fi
    fi
  done
  if [ -n "$BEST_REPO_URL" ]; then
    REPO_URL="$BEST_REPO_URL"
    echo ">>> Selected TeX Live frozen mirror for ${FROZEN_YEAR}: ${REPO_URL} (probe ${BEST_TIME}s)"
    break
  fi
  YEAR_OFFSET=$((YEAR_OFFSET + 1))
done

if [ -n "$LOCKED_REPO_URL" ]; then
  REPO_URL="$LOCKED_REPO_URL"
  echo ">>> Using locked TeX Live repository: ${REPO_URL}"
fi

if [ -z "$REPO_URL" ]; then
  echo "No frozen TeX Live repository found in the last ${MAX_YEARS_BACK} years."
  exit 1
fi

micromamba run -n r-env Rscript -e ".libPaths('${R_LIBS_USER}'); tinytex::install_tinytex(force = TRUE, dir = '${HOME}/.TinyTeX', version = '', bundle = 'TinyTeX-1', repo = '${REPO_URL}', add_path = TRUE)"

# Ensure TinyTeX binaries are on PATH for common shells.
if ! grep -q '/home/dev/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.profile"
fi
if ! grep -q '/home/dev/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >>"$HOME/.zshrc"
fi

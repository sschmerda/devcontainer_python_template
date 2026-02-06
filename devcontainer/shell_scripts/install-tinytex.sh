#!/usr/bin/env bash
set -e

echo ">>> Installing TinyTeX (frozen release) via R..."

RSCRIPT="/opt/R/4.5.2/bin/Rscript"
if [ ! -x "$RSCRIPT" ]; then
  echo "Rscript not found at $RSCRIPT"
  exit 1
fi

R_LIBS_USER="${HOME}/.local/lib/R/library"
mkdir -p "$R_LIBS_USER"
"$RSCRIPT" -e "install.packages('tinytex', repos = 'https://cloud.r-project.org', lib = '${R_LIBS_USER}')"

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
  for BASE in $FROZEN_BASES; do
    MIRROR="${BASE}/${FROZEN_YEAR}/tlnet-final"
    TLPDB_URL="${MIRROR}/tlpkg/texlive.tlpdb"
    TLPDB_XZ_URL="${MIRROR}/tlpkg/texlive.tlpdb.xz"
    if curl -fsI "$TLPDB_URL" >/dev/null 2>&1 || curl -fsI "$TLPDB_XZ_URL" >/dev/null 2>&1; then
      REPO_URL="$MIRROR"
      break
    fi
  done
  if [ -n "$REPO_URL" ]; then
    break
  fi
  YEAR_OFFSET=$((YEAR_OFFSET + 1))
done

if [ -n "$LOCKED_REPO_URL" ]; then
  REPO_URL="$LOCKED_REPO_URL"
fi

if [ -z "$REPO_URL" ]; then
  echo "No frozen TeX Live repository found in the last ${MAX_YEARS_BACK} years."
  exit 1
fi

"$RSCRIPT" -e ".libPaths('${R_LIBS_USER}'); tinytex::install_tinytex(force = TRUE, dir = '${HOME}/.TinyTeX', version = '', bundle = 'TinyTeX-1', repo = '${REPO_URL}', add_path = TRUE)"

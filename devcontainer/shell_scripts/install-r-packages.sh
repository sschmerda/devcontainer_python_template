#!/usr/bin/env sh
set -e

PROJECT_DIR="/tmp/r-environment"
PACKAGES_FILE="${PROJECT_DIR}/r-packages.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "R packages file not found: $PACKAGES_FILE"
  exit 0
fi

RSCRIPT="/opt/R/4.5.2/bin/Rscript"
if [ ! -x "$RSCRIPT" ]; then
  echo "Rscript not found at $RSCRIPT"
  exit 1
fi

R_LIBS_USER="${HOME}/.local/lib/R/library"
mkdir -p "$R_LIBS_USER"

PACKAGES="$(awk '{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if (length) print}' "$PACKAGES_FILE")"
CRAN_MIRROR="${CRAN_MIRROR:-https://cloud.r-project.org}"
PPM_MIRROR="${PPM_MIRROR:-https://packagemanager.posit.co/cran/latest}"

if [ -z "$PACKAGES" ]; then
  echo "No R packages selected; skipping."
  exit 0
fi

"$RSCRIPT" -e "install.packages('pak', repos='${CRAN_MIRROR}', lib='${R_LIBS_USER}')"

echo "Installing R packages from CRAN:"
printf '%s\n' "$PACKAGES"

printf '%s\n' "$PACKAGES" | xargs "$RSCRIPT" -e \
  "pkgs <- commandArgs(trailingOnly=TRUE); .libPaths(c('${R_LIBS_USER}', .libPaths())); options(repos=c(PPM='${PPM_MIRROR}', CRAN='${CRAN_MIRROR}'), pkgType='binary'); pak::pkg_install(pkgs, dependencies = NA, lib = '${R_LIBS_USER}', upgrade = FALSE)"

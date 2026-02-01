#!/usr/bin/env sh
set -e

PACKAGES_FILE="/tmp/r-environment/r-packages.txt"

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

echo "Installing R packages from CRAN:"
printf '%s\n' "$PACKAGES"

printf '%s\n' "$PACKAGES" | xargs "$RSCRIPT" -e \
  "pkgs <- commandArgs(trailingOnly=TRUE); options(repos=c(PPM='${PPM_MIRROR}', CRAN='${CRAN_MIRROR}')); install.packages(pkgs, lib='${R_LIBS_USER}', Ncpus=parallel::detectCores())"

# Ensure user R library is on the default .libPaths()
RPROFILE="${HOME}/.Rprofile"
if [ ! -f "$RPROFILE" ] || ! grep -q "${R_LIBS_USER}" "$RPROFILE"; then
  echo "if (dir.exists('~/.local/lib/R/library')) .libPaths(c('~/.local/lib/R/library', .libPaths()))" >>"$RPROFILE"
fi

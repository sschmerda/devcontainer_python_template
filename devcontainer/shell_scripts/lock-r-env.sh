#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

PROJECT_DIR="/home/dev/dev_container/devcontainer/r-environment"
LOCKFILE="${PROJECT_DIR}/pak.lock"
STAMP_FILE="${PROJECT_DIR}/pak.lock.created"
R_LIBS_USER="/home/dev/.local/lib/R/library"
RSCRIPT="/opt/R/4.5.2/bin/Rscript"

if [ ! -x "$RSCRIPT" ]; then
  echo "Rscript not found at $RSCRIPT"
  exit 1
fi

mkdir -p "$R_LIBS_USER"

"$RSCRIPT" -e "install.packages('pak', repos='https://cloud.r-project.org', lib='${R_LIBS_USER}')"
"$RSCRIPT" -e ".libPaths(c('${R_LIBS_USER}', '/opt/R/4.5.2/lib/R/library')); library(pak, lib.loc='${R_LIBS_USER}'); options(repos=c(PPM='https://packagemanager.posit.co/cran/latest', CRAN='https://cloud.r-project.org'), pkgType='binary'); pkgs <- readLines('${PROJECT_DIR}/r-packages.txt', warn = FALSE); pkgs <- gsub('#.*$', '', pkgs); pkgs <- trimws(pkgs); pkgs <- pkgs[pkgs != '']; if (length(pkgs) == 0) { quit(status = 0) }; pak::lockfile_create(pkgs, lockfile = '${LOCKFILE}', lib = NULL, dependencies = NA)"

printf '%s\n' "Created: $(date "+%Y-%m-%d %H:%M:%S %Z")" >"$STAMP_FILE"

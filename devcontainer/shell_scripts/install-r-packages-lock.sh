#!/usr/bin/env sh
set -e

PROJECT_DIR="/tmp/r-environment"
LOCKFILE="${PROJECT_DIR}/pak.lock"
RSCRIPT="/opt/R/4.5.2/bin/Rscript"
R_LIBS_USER="${HOME}/.local/lib/R/library"
CRAN_MIRROR="${CRAN_MIRROR:-https://cloud.r-project.org}"
PPM_MIRROR="${PPM_MIRROR:-https://packagemanager.posit.co/cran/latest}"

if [ ! -f "$LOCKFILE" ]; then
  echo "R lockfile not found: $LOCKFILE"
  echo "Falling back to latest R package install."
  exec /tmp/install-r-packages.sh
fi

if [ ! -x "$RSCRIPT" ]; then
  echo "Rscript not found at $RSCRIPT"
  exit 1
fi

mkdir -p "$R_LIBS_USER"

"$RSCRIPT" -e "install.packages('pak', repos='${CRAN_MIRROR}', lib='${R_LIBS_USER}')"
"$RSCRIPT" -e ".libPaths(c('${R_LIBS_USER}', .libPaths())); options(repos=c(PPM='${PPM_MIRROR}', CRAN='${CRAN_MIRROR}'), pkgType='binary'); pak::lockfile_install(lockfile='${LOCKFILE}', lib='${R_LIBS_USER}')"

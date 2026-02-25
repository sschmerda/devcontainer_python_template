#!/usr/bin/env sh
set -e

PACKAGES_FILE="/tmp/latex-environment/latex-packages.txt"
REPO_FILE="/tmp/latex-environment/latex-environment-lock.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "LaTeX packages file not found: $PACKAGES_FILE"
  exit 1
fi

# Ensure TinyTeX bin is on PATH for non-interactive shells
export PATH="/home/dev/bin:$PATH"

if ! command -v tlmgr >/dev/null 2>&1; then
  echo "tlmgr not found on PATH"
  exit 1
fi

install_latest() {
  # Non-lock builds intentionally use the repository configured by TinyTeX
  # (typically mirror.ctan.org -> fastest mirror).
  REPO_URL="$(tlmgr option repository | sed -n 's/.*repository)[[:space:]]*:[[:space:]]*//p' | head -n 1)"
  if [ -n "$REPO_URL" ]; then
    echo "Using current TeX Live repository: $REPO_URL"
  fi
  printf '%s\n' "$PACKAGES" | xargs tlmgr install
}

PACKAGES="$(awk '{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if (length) print}' "$PACKAGES_FILE")"

if [ -z "$PACKAGES" ]; then
  echo "No LaTeX packages selected; skipping."
  exit 0
fi

echo "Installing LaTeX packages:"
printf '%s\n' "$PACKAGES"

if [ "${DEV_ENV_LOCKED:-0}" != "1" ]; then
  install_latest
  exit 0
fi

if [ ! -f "$REPO_FILE" ]; then
  echo "LaTeX lockfile does not exist: $REPO_FILE"
  exit 1
fi

REPO_URL=""
TLPDB_SHA256=""
REPO_URL="$(awk -F= '/^repo=/{print $2}' "$REPO_FILE" | head -n 1)"
TLPDB_SHA256="$(awk -F= '/^tlpdb_sha256=/{print $2}' "$REPO_FILE" | head -n 1)"

if [ -z "$REPO_URL" ] || [ -z "$TLPDB_SHA256" ]; then
  echo "LaTeX lockfile is missing required fields (repo/tlpdb_sha256): $REPO_FILE"
  exit 1
fi

tlmgr option repository "$REPO_URL" >/dev/null

TMP_DIR="$(mktemp -d)"
TLPDB_URL="${REPO_URL}/tlpkg/texlive.tlpdb"
TLPDB_XZ_URL="${REPO_URL}/tlpkg/texlive.tlpdb.xz"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if curl -fsSL "$TLPDB_URL" -o "$TMP_DIR/texlive.tlpdb" >/dev/null 2>&1; then
  :
elif curl -fsSL "$TLPDB_XZ_URL" -o "$TMP_DIR/texlive.tlpdb.xz" >/dev/null 2>&1; then
  xz -d "$TMP_DIR/texlive.tlpdb.xz"
else
  echo "Unable to download texlive.tlpdb from ${REPO_URL}"
  exit 1
fi

CURRENT_SHA256="$(sha256sum "$TMP_DIR/texlive.tlpdb" | awk '{print $1}')"
if [ "$CURRENT_SHA256" != "$TLPDB_SHA256" ]; then
  echo "TeX Live repository has changed since lock was created."
  echo "Expected: $TLPDB_SHA256"
  echo "Current:  $CURRENT_SHA256"
  exit 1
fi

printf '%s\n' "$PACKAGES" | xargs tlmgr install

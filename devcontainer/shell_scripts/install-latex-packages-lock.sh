#!/usr/bin/env sh
set -e

PACKAGES_FILE="/tmp/latex-environment/latex-packages.txt"
REPO_FILE="/tmp/latex-environment/texlive-repo.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "LaTeX packages file not found: $PACKAGES_FILE"
  exit 0
fi

# Ensure TinyTeX bin is on PATH for non-interactive shells
export PATH="/home/dev/bin:$PATH"

if ! command -v tlmgr >/dev/null 2>&1; then
  echo "tlmgr not found on PATH"
  exit 1
fi

REPO_URL=""
TLPDB_SHA256=""
if [ -f "$REPO_FILE" ]; then
  REPO_URL="$(awk -F= '/^repo=/{print $2}' "$REPO_FILE" | head -n 1)"
  TLPDB_SHA256="$(awk -F= '/^tlpdb_sha256=/{print $2}' "$REPO_FILE" | head -n 1)"
fi

if [ -z "$REPO_URL" ] || [ -z "$TLPDB_SHA256" ]; then
  echo "LaTeX lockfile missing or incomplete; falling back to latest install."
  exec /tmp/install-latex-packages.sh
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
  echo "Unable to download texlive.tlpdb from ${REPO_URL}; falling back to latest install."
  exec /tmp/install-latex-packages.sh
fi

CURRENT_SHA256="$(sha256sum "$TMP_DIR/texlive.tlpdb" | awk '{print $1}')"
if [ "$CURRENT_SHA256" != "$TLPDB_SHA256" ]; then
  echo "TeX Live repository has changed since lock was created; falling back to latest install."
  echo "Expected: $TLPDB_SHA256"
  echo "Current:  $CURRENT_SHA256"
  exec /tmp/install-latex-packages.sh
fi

PACKAGES="$(awk '{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if (length) print}' "$PACKAGES_FILE")"

if [ -z "$PACKAGES" ]; then
  echo "No LaTeX packages selected; skipping."
  exit 0
fi

echo "Installing LaTeX packages:"
printf '%s\n' "$PACKAGES"

printf '%s\n' "$PACKAGES" | xargs tlmgr install

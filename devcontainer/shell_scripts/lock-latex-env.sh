#!/usr/bin/env sh
set -e

if [ ! -f /.dockerenv ]; then
  echo "This script must be run inside the container."
  exit 1
fi

OUT_FILE="/home/dev/dev_container/devcontainer/latex-environment/texlive-repo.txt"
STAMP="$(date "+%Y-%m-%d %H:%M:%S %Z")"

REPO_URL="${TEXLIVE_REPO_URL:-}"
TMP_DIR="$(mktemp -d)"
if [ -z "$REPO_URL" ]; then
  if command -v tlmgr >/dev/null 2>&1; then
    REPO_URL="$(tlmgr option repository | sed -n 's/.*repository)[[:space:]]*:[[:space:]]*//p' | head -n 1)"
  fi
fi

case "$REPO_URL" in
  http://*|https://*) ;;
  *) REPO_URL="";;
esac

if [ -z "$REPO_URL" ]; then
  echo "Unable to determine TeX Live repository for locking."
  if command -v tlmgr >/dev/null 2>&1; then
    echo "tlmgr option repository output:"
    tlmgr option repository || true
  fi
  exit 1
fi

TLPDB_URL="${REPO_URL}/tlpkg/texlive.tlpdb"
TLPDB_XZ_URL="${REPO_URL}/tlpkg/texlive.tlpdb.xz"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

TLPDB_FILE=""
if curl -fsSL "$TLPDB_URL" -o "$TMP_DIR/texlive.tlpdb" >/dev/null 2>&1; then
  TLPDB_FILE="$TMP_DIR/texlive.tlpdb"
elif curl -fsSL "$TLPDB_XZ_URL" -o "$TMP_DIR/texlive.tlpdb.xz" >/dev/null 2>&1; then
  xz -d "$TMP_DIR/texlive.tlpdb.xz"
  TLPDB_FILE="$TMP_DIR/texlive.tlpdb"
else
  echo "Unable to download texlive.tlpdb from ${REPO_URL}"
  exit 1
fi

TLPDB_SHA256="$(sha256sum "$TLPDB_FILE" | awk '{print $1}')"

{
  printf '# Created: %s\n' "$STAMP"
  printf '# TeX Live repository: %s\n' "$REPO_URL"
  printf 'repo=%s\n' "$REPO_URL"
  printf 'tlpdb_sha256=%s\n' "$TLPDB_SHA256"
} >"$OUT_FILE"

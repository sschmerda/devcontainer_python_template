#!/usr/bin/env sh
set -e

PACKAGES_FILE="/tmp/latex-environment/latex-packages.txt"

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

PACKAGES="$(awk '{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if (length) print}' "$PACKAGES_FILE")"

if [ -z "$PACKAGES" ]; then
  echo "No LaTeX packages selected; skipping."
  exit 0
fi

echo "Installing LaTeX packages:"
printf '%s\n' "$PACKAGES"

printf '%s\n' "$PACKAGES" | xargs tlmgr install

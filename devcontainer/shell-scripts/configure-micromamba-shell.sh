#!/usr/bin/env bash
set -euo pipefail

ZSHRC="${HOME}/.zshrc"
START_MARKER="# >>> micromamba-shell managed >>>"
END_MARKER="# <<< micromamba-shell managed <<<"

mkdir -p "$(dirname "$ZSHRC")"
touch "$ZSHRC"

tmp_file="$(mktemp)"
cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT

awk -v start="$START_MARKER" -v end="$END_MARKER" '
  $0 == start {skip=1; next}
  $0 == end {skip=0; next}
  !skip {print}
' "$ZSHRC" >"$tmp_file"

cat >>"$tmp_file" <<'EOF'
# >>> micromamba-shell managed >>>
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook --shell zsh)"
fi
# <<< micromamba-shell managed <<<
EOF

mv "$tmp_file" "$ZSHRC"

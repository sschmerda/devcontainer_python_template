#!/usr/bin/env bash
set -euo pipefail

ZSHRC="${HOME}/.zshrc"
START_MARKER="# >>> runtime-shell-env managed >>>"
END_MARKER="# <<< runtime-shell-env managed <<<"

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

cat >>"$tmp_file" <<'BLOCK'
# >>> runtime-shell-env managed >>>
if [[ -f /usr/local/bin/export-runtime-env.sh ]]; then
  () {
    emulate -L zsh
    . /usr/local/bin/export-runtime-env.sh
  }
fi
# <<< runtime-shell-env managed <<<
BLOCK

mv "$tmp_file" "$ZSHRC"

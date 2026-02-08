#!/usr/bin/env bash
set -euo pipefail

echo ">>> Installing Quarto from lockfile..."

write_quarto_runtime_env() {
  local start="# >>> quarto-runtime managed >>>"
  local end="# <<< quarto-runtime managed <<<"
  local zshrc="$HOME/.zshrc"
  local profile="$HOME/.profile"

  for target in "$zshrc" "$profile"; do
    touch "$target"
    sed -i "/${start}/,/${end}/d" "$target"
    cat >>"$target" <<'EOF'
# >>> quarto-runtime managed >>>
export QUARTO_PYTHON="/home/dev/.local/share/mamba/envs/python-env/bin/python"
export QUARTO_JUPYTER="/home/dev/.local/share/mamba/envs/python-env/bin/jupyter"
export QUARTO_R="/home/dev/.local/share/mamba/envs/r-env/bin/R"
export RETICULATE_PYTHON="/home/dev/.local/share/mamba/envs/python-env/bin/python"
export PATH="/home/dev/.local/bin:$PATH"
# <<< quarto-runtime managed <<<
EOF
  done
}

LOCK_FILE="/tmp/quarto-environment/quarto-lock.env"
if [ ! -f "$LOCK_FILE" ]; then
  echo "Quarto lockfile not found: $LOCK_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$LOCK_FILE"

if [ -z "${QUARTO_TAG:-}" ] || [ -z "${QUARTO_VERSION:-}" ]; then
  echo "Missing QUARTO_TAG or QUARTO_VERSION in $LOCK_FILE"
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)
    URL="${QUARTO_LINUX_AMD64_URL:-}"
    ;;
  aarch64|arm64)
    URL="${QUARTO_LINUX_ARM64_URL:-}"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

if [ -z "$URL" ]; then
  echo "Missing locked Quarto URL for architecture ${ARCH} in $LOCK_FILE"
  exit 1
fi

echo ">>> Locked Quarto release: ${QUARTO_TAG}"
curl -fL "$URL" -o /tmp/quarto.tar.gz
rm -rf /tmp/quarto-extract
mkdir -p /tmp/quarto-extract
tar -xzf /tmp/quarto.tar.gz -C /tmp/quarto-extract

QUARTO_BIN="$(find /tmp/quarto-extract -type f -name quarto | head -n 1)"
if [ -z "$QUARTO_BIN" ] || [ ! -x "$QUARTO_BIN" ]; then
  echo "Quarto binary not found in extracted archive."
  exit 1
fi
SRC_DIR="$(dirname "$(dirname "$QUARTO_BIN")")"

INSTALL_BASE="$HOME/.local/share/quarto"
INSTALL_DIR="$INSTALL_BASE/${QUARTO_VERSION}"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_BASE" "$BIN_DIR"
rm -rf "$INSTALL_DIR"
mv "$SRC_DIR" "$INSTALL_DIR"
ln -sfn "$INSTALL_DIR/bin/quarto" "$BIN_DIR/quarto"

rm -rf /tmp/quarto-extract /tmp/quarto.tar.gz
write_quarto_runtime_env

"$BIN_DIR/quarto" --version

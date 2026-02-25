#!/usr/bin/env bash
set -euo pipefail

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

resolve_latest_url() {
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64)
      ARCH_SUFFIX="linux-amd64"
      ;;
    aarch64|arm64)
      ARCH_SUFFIX="linux-arm64"
      ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  LATEST_TAG="$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n 1)"
  if [ -z "$LATEST_TAG" ]; then
    echo "Unable to determine latest Quarto release tag from GitHub."
    exit 1
  fi

  VERSION="${LATEST_TAG#v}"
  ASSET="quarto-${VERSION}-${ARCH_SUFFIX}.tar.gz"
  URL="https://github.com/quarto-dev/quarto-cli/releases/download/${LATEST_TAG}/${ASSET}"
  echo ">>> Selected Quarto release: ${LATEST_TAG}"
}

resolve_locked_url() {
  LOCK_FILE="/tmp/quarto-environment/quarto-lock.env"
  if [ ! -f "$LOCK_FILE" ]; then
    echo "Quarto lockfile does not exist: $LOCK_FILE"
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
      SHA256="${QUARTO_LINUX_AMD64_SHA256:-}"
      ;;
    aarch64|arm64)
      URL="${QUARTO_LINUX_ARM64_URL:-}"
      SHA256="${QUARTO_LINUX_ARM64_SHA256:-}"
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
  if [ -z "$SHA256" ]; then
    echo "Missing locked Quarto SHA256 for architecture ${ARCH} in $LOCK_FILE"
    exit 1
  fi

  VERSION="${QUARTO_VERSION}"
  echo ">>> Locked Quarto release: ${QUARTO_TAG}"
}

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  echo ">>> Installing Quarto from lockfile..."
  resolve_locked_url
else
  echo ">>> Installing Quarto from latest stable GitHub release..."
  resolve_latest_url
fi

curl -fL "$URL" -o /tmp/quarto.tar.gz
if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  ACTUAL_SHA256="$(sha256sum /tmp/quarto.tar.gz | awk '{print $1}')"
  if [ "$ACTUAL_SHA256" != "$SHA256" ]; then
    echo "Quarto checksum mismatch for locked asset."
    echo "Expected: $SHA256"
    echo "Actual:   $ACTUAL_SHA256"
    exit 1
  fi
fi
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
INSTALL_DIR="$INSTALL_BASE/${VERSION}"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_BASE" "$BIN_DIR"
rm -rf "$INSTALL_DIR"
mv "$SRC_DIR" "$INSTALL_DIR"
ln -sfn "$INSTALL_DIR/bin/quarto" "$BIN_DIR/quarto"

rm -rf /tmp/quarto-extract /tmp/quarto.tar.gz
write_quarto_runtime_env

"$BIN_DIR/quarto" --version

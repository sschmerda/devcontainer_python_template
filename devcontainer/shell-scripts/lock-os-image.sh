#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env-vars/.env.build"
OS_LOCK_DIR="${ROOT_DIR}/os-environment"
OS_LOCK_FILE="${OS_LOCK_DIR}/os-lock.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

SOURCE_IMAGE="$(awk -F= '/^DEVCONTAINER_OS_IMAGE=/{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
if [ -z "$SOURCE_IMAGE" ]; then
  echo "DEVCONTAINER_OS_IMAGE is not set in $ENV_FILE"
  exit 1
fi

resolve_digest_for_arch() {
  arch="$1"
  digest_ref="$(
    docker buildx imagetools inspect "$SOURCE_IMAGE" 2>/dev/null | awk -v target="linux/${arch}" '
      $1 == "Name:" {name=$2}
      $1 == "Platform:" {
        if ($2 == target || index($2, target "/") == 1) {
          if (name ~ /@sha256:/) {
            print name
            found=1
            exit
          }
        }
      }
      END {
        if (!found) exit 1
      }
    '
  )" || true

  if [ -z "$digest_ref" ]; then
    echo "Failed to resolve linux/${arch} child digest for ${SOURCE_IMAGE}."
    echo "Ensure ${SOURCE_IMAGE} is a multi-arch image with a linux/${arch} manifest."
    exit 1
  fi
  printf '%s' "$digest_ref"
}

LOCKED_IMAGE_AMD64="$(resolve_digest_for_arch amd64)"
LOCKED_IMAGE_ARM64="$(resolve_digest_for_arch arm64)"

HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
  x86_64|amd64)
    LOCKED_IMAGE_HOST="$LOCKED_IMAGE_AMD64"
    ;;
  aarch64|arm64)
    LOCKED_IMAGE_HOST="$LOCKED_IMAGE_ARM64"
    ;;
  *)
    echo "Unsupported host architecture: $HOST_ARCH"
    exit 1
    ;;
esac

mkdir -p "$OS_LOCK_DIR"
{
  printf '# Created: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'DEVCONTAINER_OS_IMAGE_SOURCE=%s\n' "$SOURCE_IMAGE"
  printf 'DEVCONTAINER_OS_IMAGE_AMD64=%s\n' "$LOCKED_IMAGE_AMD64"
  printf 'DEVCONTAINER_OS_IMAGE_ARM64=%s\n' "$LOCKED_IMAGE_ARM64"
} >"$OS_LOCK_FILE"

echo "Created ${OS_LOCK_FILE}"

#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/env-vars/.env"
LOCK_DIR="${ROOT_DIR}/os-environment"
LOCK_FILE="${LOCK_DIR}/os-lock.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

SOURCE_IMAGE="$(awk -F= '/^DEVCONTAINER_OS_IMAGE=/{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
if [ -z "$SOURCE_IMAGE" ]; then
  echo "DEVCONTAINER_OS_IMAGE is not set in $ENV_FILE"
  exit 1
fi

if printf '%s' "$SOURCE_IMAGE" | grep -q '@sha256:'; then
  LOCKED_IMAGE="$SOURCE_IMAGE"
else
  docker pull "$SOURCE_IMAGE" >/dev/null
  LOCKED_IMAGE="$(docker image inspect --format '{{index .RepoDigests 0}}' "$SOURCE_IMAGE" 2>/dev/null || true)"
  if [ -z "$LOCKED_IMAGE" ]; then
    echo "Failed to resolve digest for $SOURCE_IMAGE"
    exit 1
  fi
fi

mkdir -p "$LOCK_DIR"
{
  printf '# Created: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf 'DEVCONTAINER_OS_IMAGE_SOURCE=%s\n' "$SOURCE_IMAGE"
  printf 'DEVCONTAINER_OS_IMAGE=%s\n' "$LOCKED_IMAGE"
} >"$LOCK_FILE"

echo "Created ${LOCK_FILE}"

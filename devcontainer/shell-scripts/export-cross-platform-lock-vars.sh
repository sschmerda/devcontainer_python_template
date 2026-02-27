#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OS_LOCK_FILE="${ROOT_DIR}/os-environment/os-lock.env"
SERVICES_LOCK_FILE="${ROOT_DIR}/services-environment/services-lock.env"
MODE="${1:-all}"

case "$MODE" in
  os|services|all)
    ;;
  *)
    echo "Usage: export-cross-platform-lock-vars.sh [os|services|all]" >&2
    exit 1
    ;;
esac

ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64|amd64)
    ARCH_SUFFIX="AMD64"
    ;;
  aarch64|arm64)
    ARCH_SUFFIX="ARM64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH_RAW" >&2
    exit 1
    ;;
esac

read_value() {
  file="$1"
  key="$2"
  awk -F= -v k="$key" '
    $0 ~ /^[[:space:]]*#/ {next}
    NF >= 2 && $1 == k {print substr($0, index($0, "=")+1); exit}
  ' "$file"
}

emit_arch_value() {
  file="$1"
  base_key="$2"
  arch_key="${base_key}_${ARCH_SUFFIX}"
  value="$(read_value "$file" "$arch_key")"
  if [ -z "$value" ]; then
    echo "Missing ${arch_key} in ${file}" >&2
    exit 1
  fi
  printf 'export %s=%s\n' "$base_key" "$value"
}

emit_os_values() {
  [ -f "$OS_LOCK_FILE" ] || {
    echo "Missing ${OS_LOCK_FILE}" >&2
    exit 1
  }
  emit_arch_value "$OS_LOCK_FILE" "DEVCONTAINER_OS_IMAGE"
}

emit_service_values() {
  [ -f "$SERVICES_LOCK_FILE" ] || return 0
  awk -F= '
    $0 !~ /^[[:space:]]*#/ && $1 ~ /_IMAGE_LOCK_(AMD64|ARM64)$/ {
      name=$1
      sub(/_(AMD64|ARM64)$/, "", name)
      seen[name]=1
    }
    END {
      for (k in seen) print k
    }
  ' "$SERVICES_LOCK_FILE" | sort | while IFS= read -r service_lock_key; do
    [ -n "$service_lock_key" ] || continue
    emit_arch_value "$SERVICES_LOCK_FILE" "$service_lock_key"
  done
}

if [ "$MODE" = "os" ] || [ "$MODE" = "all" ]; then
  emit_os_values
fi

if [ "$MODE" = "services" ] || [ "$MODE" = "all" ]; then
  emit_service_values
fi

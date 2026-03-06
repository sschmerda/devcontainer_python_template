#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_FILE="${ROOT_DIR}/services-environment/services-lock.env"
SERVICES_RAW="${ACTIVE_SERVICES:-postgres}"
MODE="${1:-lock}"
# Compose files contain DEV_ENV_LOCKED build args; default prevents warning noise.
: "${DEV_ENV_LOCKED:=0}"
export DEV_ENV_LOCKED
compose_cmd() {
  docker compose \
    --env-file "${ROOT_DIR}/env-vars/.env" \
    --env-file "${ROOT_DIR}/env-vars/.env.secrets" \
    -f "${ROOT_DIR}/docker/docker-compose.yml" \
    -f "${ROOT_DIR}/docker/docker-compose.services.yml" \
    "$@"
}

COMPOSE_CONFIG="$(compose_cmd config)"

services_to_list() {
  # Allow newline/comma/space separated values from ACTIVE_SERVICES.
  printf '%s\n' "$SERVICES_RAW" | tr ',\n\t' '   '
}

services_for_comment() {
  services_to_list | xargs echo | tr ' ' ','
}

service_lock_var() {
  printf '%s_IMAGE_LOCK' "$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')"
}

service_arch_lock_var() {
  printf '%s_%s' "$(service_lock_var "$1")" "$2"
}

service_image_ref() {
  svc="$1"
  printf '%s\n' "$COMPOSE_CONFIG" | awk -v svc="$svc" '
    $0 ~ "^  "svc":" {in_svc=1; next}
    in_svc && $0 ~ "^  [^ ]" {in_svc=0}
    in_svc && $1 == "image:" {
      val=$2
      gsub(/"/, "", val)
      print val
      exit
    }
  '
}

service_has_build() {
  svc="$1"
  printf '%s\n' "$COMPOSE_CONFIG" | awk -v svc="$svc" '
    $0 ~ "^  "svc":" {in_svc=1; next}
    in_svc && $0 ~ "^  [^ ]" {in_svc=0}
    in_svc && $1 == "build:" {print "yes"; exit}
  ' | grep -q yes
}

lock_value() {
  key="$1"
  [ -f "$LOCK_FILE" ] || return 0
  awk -F= -v k="$key" '
    $0 ~ /^[[:space:]]*#/ {next}
    NF >= 2 && $1 == k {print substr($0, index($0, "=")+1); exit}
  ' "$LOCK_FILE"
}

lock_image() {
  var_name="$1"
  image_ref="$2"
  arch="$3"

  if [ -z "$image_ref" ]; then
    echo "No image reference found for ${var_name}" >&2
    exit 1
  fi

  if printf '%s' "$image_ref" | grep -q '@sha256:'; then
    printf '%s=%s\n' "$var_name" "$image_ref"
    return
  fi

  digest_ref="$(
    docker buildx imagetools inspect "$image_ref" 2>/dev/null | awk -v target="linux/${arch}" '
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
    echo "Failed to resolve linux/${arch} child digest for ${image_ref}." >&2
    echo "Ensure ${image_ref} is a multi-arch image with a linux/${arch} manifest." >&2
    exit 1
  fi

  printf '%s=%s\n' "$var_name" "$digest_ref"
}

validate_locks() {
  missing=0

  for service in $(services_to_list); do
    [ -n "$service" ] || continue
    if service_has_build "$service"; then
      continue
    fi
    var_name_amd64="$(service_arch_lock_var "$service" "AMD64")"
    var_name_arm64="$(service_arch_lock_var "$service" "ARM64")"
    value_amd64="$(lock_value "$var_name_amd64")"
    value_arm64="$(lock_value "$var_name_arm64")"
    if [ -z "$value_amd64" ]; then
      echo "Missing lock value for ${service}: ${var_name_amd64}" >&2
      missing=1
    fi
    if [ -z "$value_arm64" ]; then
      echo "Missing lock value for ${service}: ${var_name_arm64}" >&2
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    echo "Run make lock-services to generate missing lock entries." >&2
    exit 1
  fi
}

if [ "$MODE" = "validate" ]; then
  validate_locks
  exit 0
fi

if [ "$MODE" != "lock" ]; then
  echo "Usage: lock-services-env.sh [lock|validate]" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOCK_FILE")"

{
  echo "# Created at: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "# services: $(services_for_comment)"
  for service in $(services_to_list); do
    [ -n "$service" ] || continue
    if service_has_build "$service"; then
      echo "# ${service}: build-based service (not digest-locked)"
      continue
    fi
    lock_image "$(service_arch_lock_var "$service" "AMD64")" "$(service_image_ref "$service")" "amd64"
    lock_image "$(service_arch_lock_var "$service" "ARM64")" "$(service_image_ref "$service")" "arm64"
  done
} > "$LOCK_FILE"

echo "Created ${LOCK_FILE}"

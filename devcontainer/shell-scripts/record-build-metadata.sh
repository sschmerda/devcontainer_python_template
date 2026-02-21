#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCOPE="${1:-}"
COMMAND_NAME="${2:-}"

if [ -z "$SCOPE" ] || [ -z "$COMMAND_NAME" ]; then
  echo "Usage: record-build-metadata.sh <dev|services> <command-name>" >&2
  exit 1
fi

if [ "${DEV_ENV_LOCKED:-0}" = "1" ]; then
  MODE="lock"
else
  MODE="non-lock"
fi

case "$SCOPE" in
  dev) LOG_FILE="${ROOT_DIR}/build-metadata/dev-env-builds-${MODE}.log" ;;
  services) LOG_FILE="${ROOT_DIR}/build-metadata/services-builds-${MODE}.log" ;;
  *)
    echo "Unsupported scope: ${SCOPE}" >&2
    exit 1
    ;;
esac

mkdir -p "${ROOT_DIR}/build-metadata"

docker_compose_cmd() {
  docker compose \
    --env-file "${ROOT_DIR}/env-vars/.env" \
    --env-file "${ROOT_DIR}/env-vars/.env.secrets" \
    "$@"
}

compose_files_for_scope() {
  case "$SCOPE" in
    dev)
      printf '%s' "-f ${ROOT_DIR}/docker/docker-compose.yml"
      if printf '%s' "$COMMAND_NAME" | grep -q "data-mount"; then
        printf ' %s' "-f ${ROOT_DIR}/docker/docker-compose.data.yml"
      fi
      ;;
    services)
      printf '%s %s' "-f ${ROOT_DIR}/docker/docker-compose.yml" "-f ${ROOT_DIR}/docker/docker-compose.services.yml"
      if printf '%s' "$COMMAND_NAME" | grep -q "services-lock"; then
        if [ -f "${ROOT_DIR}/services-environment/services-lock.env" ]; then
          printf ' %s' "--env-file ${ROOT_DIR}/services-environment/services-lock.env"
        fi
        printf ' %s' "-f ${ROOT_DIR}/docker/docker-compose.services-lock.yml"
      fi
      ;;
  esac
}

service_image_from_config() {
  service="$1"
  printf '%s\n' "$COMPOSE_CONFIG" | awk -v svc="$service" '
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

service_container_name_from_config() {
  service="$1"
  printf '%s\n' "$COMPOSE_CONFIG" | awk -v svc="$service" '
    $0 ~ "^  "svc":" {in_svc=1; next}
    in_svc && $0 ~ "^  [^ ]" {in_svc=0}
    in_svc && $1 == "container_name:" {
      val=$2
      gsub(/"/, "", val)
      print val
      exit
    }
  '
}

service_container_size_from_runtime() {
  service="$1"
  container_id="$(eval docker_compose_cmd "$compose_args" ps -q "$service" 2>/dev/null | head -n 1)"
  if [ -z "${container_id:-}" ]; then
    echo "unknown"
    return
  fi
  size_val="$(docker ps -a --size --filter "id=${container_id}" --format '{{.Size}}' 2>/dev/null | head -n 1)"
  if [ -z "${size_val:-}" ]; then
    echo "unknown"
  else
    echo "$size_val"
  fi
}

bytes_to_human() {
  bytes="$1"
  awk -v b="$bytes" '
    function human(x,   i, units, out) {
      units[0]="B"; units[1]="KiB"; units[2]="MiB"; units[3]="GiB"; units[4]="TiB";
      i=0;
      while (x >= 1024 && i < 4) { x = x / 1024; i++ }
      out = sprintf("%.2f %s", x, units[i]);
      return out;
    }
    BEGIN { print human(b) }'
}

host_os="$(uname -s 2>/dev/null || echo unknown)"
host_kernel="$(uname -r 2>/dev/null || echo unknown)"
host_arch="$(uname -m 2>/dev/null || echo unknown)"

cpu_model="unknown"
if [ -r /proc/cpuinfo ]; then
  cpu_model="$(awk -F': ' '/^model name[[:space:]]*:/ {print $2; exit} /^Hardware[[:space:]]*:/ {print $2; exit}' /proc/cpuinfo)"
elif [ "$host_os" = "Darwin" ]; then
  cpu_model="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
  if [ -z "$cpu_model" ]; then
    cpu_model="$(sysctl -n hw.model 2>/dev/null || true)"
  fi
fi
[ -n "$cpu_model" ] || cpu_model="unknown"

ram_bytes=""
if [ -r /proc/meminfo ]; then
  ram_kib="$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)"
  if [ -n "${ram_kib:-}" ]; then
    ram_bytes=$((ram_kib * 1024))
  fi
elif [ "$host_os" = "Darwin" ]; then
  ram_bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
fi
ram_human="unknown"
if [ -n "${ram_bytes:-}" ]; then
  ram_human="$(bytes_to_human "$ram_bytes")"
fi

docker_client_version="$(docker --version 2>/dev/null || echo unavailable)"
docker_compose_version="$(docker compose version 2>/dev/null || echo unavailable)"
docker_server_version="$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)"
if [ -z "${docker_server_version:-}" ]; then
  docker_server_version="unavailable"
fi
docker_context_name="$(docker context show 2>/dev/null || echo unavailable)"
build_duration_seconds="${BUILD_DURATION_SECONDS:-unknown}"

duration_human() {
  val="$1"
  case "$val" in
    ''|*[!0-9]*)
      echo "unknown"
      return
      ;;
  esac
  h=$((val / 3600))
  m=$(((val % 3600) / 60))
  s=$((val % 60))
  printf '%02dh:%02dm:%02ds' "$h" "$m" "$s"
}

compose_args="$(compose_files_for_scope)"
COMPOSE_CONFIG="$(eval docker_compose_cmd "$compose_args" config 2>/dev/null || true)"

services_have_volume_mounts() {
  printf '%s\n' "$COMPOSE_CONFIG" | awk '
    /^services:/ {in_services=1; next}
    in_services && /^[^ ]/ {in_services=0}
    in_services && /^    volumes:/ {in_volumes=1; next}
    in_services && in_volumes && /^      - / {print "true"; exit}
    in_services && in_volumes && /^    [^ ]/ {in_volumes=0}
  '
}

if [ "$SCOPE" = "dev" ]; then
  services_to_log="dev"
else
  services_to_log="$(
    printf '%s\n' "$COMPOSE_CONFIG" | awk '
      /^services:/ {in_services=1; next}
      in_services && /^[^ ]/ {in_services=0}
      in_services && /^  [^ ]+:/ {svc=$1; sub(":$", "", svc); if (svc != "dev") print svc}
    '
  )"
fi

services_delimited=""
if [ -n "${services_to_log:-}" ]; then
  for svc in $services_to_log; do
    [ -n "$svc" ] || continue
    if [ -n "$services_delimited" ]; then
      services_delimited="${services_delimited} | "
    fi
    services_delimited="${services_delimited}${svc}"
  done
fi

sanitize_inline() {
  printf '%s' "$1" | tr '\n' ' ' | tr '\r' ' ' | tr '\t' ' '
}

format_container_size() {
  raw="$1"
  if [ -z "$raw" ] || [ "$raw" = "unknown" ]; then
    echo "unknown"
    return
  fi
  writable="$(printf '%s' "$raw" | sed -E 's/ \(virtual .*//')"
  virtual="$(printf '%s' "$raw" | sed -nE 's/.*\(virtual ([^)]+)\).*/\1/p')"
  if [ -n "$virtual" ]; then
    printf 'writable=%s, virtual=%s' "$writable" "$virtual"
  else
    printf 'writable=%s' "$writable"
  fi
}

image_summary=""
image_size_summary=""
container_summary=""
container_size_summary=""
if [ -n "${services_to_log:-}" ]; then
  for svc in $services_to_log; do
    [ -n "$svc" ] || continue
    container_name="$(service_container_name_from_config "$svc")"
    if [ -z "${container_name:-}" ]; then
      container_name="default"
    fi
    if [ -n "$container_summary" ]; then
      container_summary="${container_summary} | "
    fi
    container_summary="${container_summary}${container_name}"
    container_size="$(service_container_size_from_runtime "$svc")"
    container_size_fmt="$(format_container_size "$container_size")"
    if [ -n "$container_size_summary" ]; then
      container_size_summary="${container_size_summary} | "
    fi
    container_size_summary="${container_size_summary}${container_name}:{${container_size_fmt}}"
    image_ref="$(service_image_from_config "$svc")"
    if [ -z "${image_ref:-}" ]; then
      if [ -n "$image_summary" ]; then
        image_summary="${image_summary} | "
      fi
      image_summary="${image_summary}missing-in-config(${svc})"
      if [ -n "$image_size_summary" ]; then
        image_size_summary="${image_size_summary} | "
      fi
      image_size_summary="${image_size_summary}missing-in-config(${svc}):{unknown}"
      continue
    fi
    image_id="$(docker image inspect "$image_ref" --format '{{.Id}}' 2>/dev/null || true)"
    image_size_bytes="$(docker image inspect "$image_ref" --format '{{.Size}}' 2>/dev/null || true)"
    if [ -n "${image_size_bytes:-}" ]; then
      image_size_human="$(bytes_to_human "$image_size_bytes")"
    else
      image_size_human="unknown"
    fi
    image_docker_ls_size="unknown"
    if [ -n "${image_id:-}" ]; then
      image_docker_ls_size="$(
        docker image ls --no-trunc --format '{{.ID}} {{.Size}}' 2>/dev/null \
          | awk -v id="$image_id" '$1 == id {print $2; exit}'
      )"
      [ -n "$image_docker_ls_size" ] || image_docker_ls_size="unknown"
    fi
    if [ -n "$image_summary" ]; then
      image_summary="${image_summary} | "
    fi
    image_summary="${image_summary}${image_ref}"
    if [ -n "$image_size_summary" ]; then
      image_size_summary="${image_size_summary} | "
    fi
    image_size_summary="${image_size_summary}${image_ref}:{inspect=${image_size_human}, docker_ls=${image_docker_ls_size}}"
  done
fi

services_inline="$(sanitize_inline "$services_delimited")"
containers_inline="$(sanitize_inline "$container_summary")"
container_sizes_inline="$(sanitize_inline "$container_size_summary")"
images_inline="$(sanitize_inline "$image_summary")"
image_sizes_inline="$(sanitize_inline "$image_size_summary")"

data_mount_used="false"
if [ "$SCOPE" = "dev" ] && printf '%s' "$COMMAND_NAME" | grep -q "data-mount"; then
  data_mount_used="true"
elif [ "$SCOPE" = "services" ] && [ "$(services_have_volume_mounts)" = "true" ]; then
  data_mount_used="true"
fi

if [ "$SCOPE" = "dev" ]; then
  cat > "$LOG_FILE" <<EOF
TIMESTAMP_UTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
COMMAND=${COMMAND_NAME}
BUILD_DURATION_SECONDS=${build_duration_seconds}
BUILD_DURATION_HUMAN=$(duration_human "$build_duration_seconds")
HOST_OS=${host_os}
HOST_KERNEL=${host_kernel}
HOST_ARCH=${host_arch}
HOST_CPU=${cpu_model}
HOST_RAM=${ram_human}
DOCKER_CLIENT=$(sanitize_inline "$docker_client_version")
DOCKER_COMPOSE=$(sanitize_inline "$docker_compose_version")
DOCKER_SERVER=$(sanitize_inline "$docker_server_version")
DOCKER_CONTEXT=${docker_context_name}
SERVICE_NAME=${services_inline}
IMAGE_NAME=${images_inline}
IMAGE_SIZE=${image_sizes_inline}
CONTAINER_NAME=${containers_inline}
CONTAINER_SIZE=${container_sizes_inline}
DATA_MOUNT_USED=${data_mount_used}
EOF
else
  cat > "$LOG_FILE" <<EOF
TIMESTAMP_UTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
COMMAND=${COMMAND_NAME}
BUILD_DURATION_SECONDS=${build_duration_seconds}
BUILD_DURATION_HUMAN=$(duration_human "$build_duration_seconds")
HOST_OS=${host_os}
HOST_KERNEL=${host_kernel}
HOST_ARCH=${host_arch}
HOST_CPU=${cpu_model}
HOST_RAM=${ram_human}
DOCKER_CLIENT=$(sanitize_inline "$docker_client_version")
DOCKER_COMPOSE=$(sanitize_inline "$docker_compose_version")
DOCKER_SERVER=$(sanitize_inline "$docker_server_version")
DOCKER_CONTEXT=${docker_context_name}
SERVICE_NAMES=${services_inline}
IMAGE_NAMES=${images_inline}
IMAGE_SIZES=${image_sizes_inline}
CONTAINER_NAMES=${containers_inline}
CONTAINER_SIZES=${container_sizes_inline}
DATA_MOUNT_USED=${data_mount_used}
EOF
fi

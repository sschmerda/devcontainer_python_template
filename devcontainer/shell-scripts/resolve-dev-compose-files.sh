#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

: "${ENV_UTILS:=$ROOT_DIR/shell-scripts/env-file-utils.sh}"
# shellcheck disable=SC1090
. "$ENV_UTILS"

: "${ENABLE_HOST_GIT_ACCESS:=$(read_env_var "env-vars/.env.runtime" "ENABLE_HOST_GIT_ACCESS")}"
: "${HOST_DATA_DIR:=$(read_env_var "env-vars/.env.secrets.runtime" "HOST_DATA_DIR")}"
: "${HOST_SSH_AUTH_SOCK_PATH:=$(read_env_var "env-vars/.env.secrets.runtime" "HOST_SSH_AUTH_SOCK_PATH")}"
: "${HOST_SSH_CONFIG_PATH:=$(read_env_var "env-vars/.env.secrets.runtime" "HOST_SSH_CONFIG_PATH")}"
: "${HOST_SSH_KNOWN_HOSTS_PATH:=$(read_env_var "env-vars/.env.secrets.runtime" "HOST_SSH_KNOWN_HOSTS_PATH")}"

compose_files="-f docker/docker-compose.yml"

is_docker_desktop=false
uname_s=$(uname -s 2>/dev/null || true)
case "$uname_s" in
  Darwin)
    is_docker_desktop=true
    ;;
  Linux)
    if [ -n "${WSL_INTEROP:-}" ] || [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
      is_docker_desktop=true
    else
      docker_operating_system=$(docker info --format '{{.OperatingSystem}}' 2>/dev/null || true)
      case "$docker_operating_system" in
        *Docker\ Desktop*) is_docker_desktop=true ;;
      esac
    fi
    ;;
esac

if [ "${ENABLE_HOST_GIT_ACCESS:-false}" = "true" ]; then
  if [ "$is_docker_desktop" = "true" ]; then
    compose_files="$compose_files -f docker/docker-compose.git-desktop.yml"
  else
    if [ -z "${HOST_SSH_AUTH_SOCK_PATH:-}" ]; then
      echo "HOST_SSH_AUTH_SOCK_PATH is empty. Set it in devcontainer/env-vars/.env.secrets.runtime." >&2
      exit 1
    fi
    case "${HOST_SSH_AUTH_SOCK_PATH}" in
      /*) ;;
      *)
        echo "HOST_SSH_AUTH_SOCK_PATH must be an absolute path: ${HOST_SSH_AUTH_SOCK_PATH}" >&2
        exit 1
        ;;
    esac
    if [ ! -S "${HOST_SSH_AUTH_SOCK_PATH}" ]; then
      echo "HOST_SSH_AUTH_SOCK_PATH is not a socket: ${HOST_SSH_AUTH_SOCK_PATH}" >&2
      exit 1
    fi
    compose_files="$compose_files -f docker/docker-compose.git.yml"
  fi

  if [ -n "${HOST_SSH_CONFIG_PATH:-}" ]; then
    case "${HOST_SSH_CONFIG_PATH}" in
      /*) ;;
      *)
        echo "HOST_SSH_CONFIG_PATH must be an absolute path: ${HOST_SSH_CONFIG_PATH}" >&2
        exit 1
        ;;
    esac
    if [ ! -f "${HOST_SSH_CONFIG_PATH}" ]; then
      echo "HOST_SSH_CONFIG_PATH does not exist: ${HOST_SSH_CONFIG_PATH}" >&2
      exit 1
    fi
    compose_files="$compose_files -f docker/docker-compose.git-ssh-config.yml"
  fi

  if [ -n "${HOST_SSH_KNOWN_HOSTS_PATH:-}" ]; then
    case "${HOST_SSH_KNOWN_HOSTS_PATH}" in
      /*) ;;
      *)
        echo "HOST_SSH_KNOWN_HOSTS_PATH must be an absolute path: ${HOST_SSH_KNOWN_HOSTS_PATH}" >&2
        exit 1
        ;;
    esac
    if [ ! -f "${HOST_SSH_KNOWN_HOSTS_PATH}" ]; then
      echo "HOST_SSH_KNOWN_HOSTS_PATH does not exist: ${HOST_SSH_KNOWN_HOSTS_PATH}" >&2
      exit 1
    fi
    compose_files="$compose_files -f docker/docker-compose.git-known-hosts.yml"
  fi
fi

if [ -n "${HOST_DATA_DIR:-}" ]; then
  case "${HOST_DATA_DIR}" in
    /*) ;;
    *)
      echo "HOST_DATA_DIR must be an absolute path: ${HOST_DATA_DIR}" >&2
      exit 1
      ;;
  esac
  if [ ! -d "${HOST_DATA_DIR}" ]; then
    echo "HOST_DATA_DIR does not exist: ${HOST_DATA_DIR}" >&2
    exit 1
  fi
  compose_files="$compose_files -f docker/docker-compose.data.yml"
fi

printf '%s\n' "$compose_files"

# Variables
ifneq (,$(wildcard .env))
  include .env
  export
endif

JUPYTER_PORT ?= 8888
COMPOSE_FILE=docker-compose.yml
# Must match the service name under `services:` in docker-compose.yml.
SERVICE=dev

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  UID_ARG := UID=$(shell id -u)
  GID_ARG := GID=$(shell id -g)
endif

COMPOSE_CMD = $(UID_ARG) $(GID_ARG) docker compose -f $(COMPOSE_FILE)

# Build and start container
.PHONY: up-env
up-env:
	MAMBA_ENV_FILE=mamba_environment/environment.yml $(COMPOSE_CMD) up -d --build

# Rebuild container from scratch and start
.PHONY: rebuild-env
rebuild-env:
	MAMBA_ENV_FILE=mamba_environment/environment.yml $(COMPOSE_CMD) build --no-cache
	MAMBA_ENV_FILE=mamba_environment/environment.yml $(COMPOSE_CMD) up -d

# Build and start container from lockfile
.PHONY: up-lock
up-lock:
	MAMBA_ENV_FILE=mamba_environment/conda-lock.yml $(COMPOSE_CMD) up -d --build

# Rebuild container from lockfile and start
.PHONY: rebuild-lock
rebuild-lock:
	MAMBA_ENV_FILE=mamba_environment/conda-lock.yml $(COMPOSE_CMD) build --no-cache
	MAMBA_ENV_FILE=mamba_environment/conda-lock.yml $(COMPOSE_CMD) up -d

# Generate lockfile (run inside container only)
.PHONY: env-lock
env-lock:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@set -e; \
	ts=$$(date "+%Y-%m-%d %H:%M:%S %Z"); \
	cd /home/dev/dev_container/devcontainer/mamba_environment; \
	rm -f conda-lock.yml; \
	conda-lock lock -f environment.yml --platform linux-64 --platform linux-aarch64 --lockfile conda-lock.yml; \
	tmp=$$(mktemp); \
	printf '# Created: %s\n' "$$ts" > "$$tmp"; \
	cat conda-lock.yml >> "$$tmp"; \
	mv "$$tmp" conda-lock.yml

# Ensure terminal definition exists in the container
.PHONY: terminfo
terminfo:
	@if ! command -v infocmp >/dev/null 2>&1; then \
		echo "infocmp not found on host; install ncurses tools to enable terminfo import (may still work if container already has matching terminfo via ncurses-term)."; \
		exit 0; \
	fi
	infocmp -x "$$TERM" | $(COMPOSE_CMD) exec -T $(SERVICE) sh -lc 'tic -x -'

# Export JupyterLab user settings to build_assets (run inside container only)
.PHONY: jupyter-settings-export
jupyter-settings-export:
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/export-jupyterlab-settings.sh"

# Restore JupyterLab user settings from build_assets (run inside container only)
.PHONY: jupyter-settings-restore
jupyter-settings-restore:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/restore-jupyterlab-settings.sh"

# Enter container in Zsh
.PHONY: shell
shell: terminfo
	$(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) zsh

# Enter container in tmux
.PHONY: tmux
tmux: terminfo
	$(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) tmux

# Open VS Code and manually connect to the container
.PHONY: vscode
vscode:
	code .

# Start JupyterLab inside container and expose port from .env
.PHONY: jupyter
jupyter:
	$(COMPOSE_CMD) exec $(SERVICE) sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/jupyter-with-token.sh"

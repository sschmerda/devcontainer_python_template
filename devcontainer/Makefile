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
.PHONY: up
up:
	$(COMPOSE_CMD) up -d --build

# Rebuild container from scratch and start
.PHONY: rebuild
rebuild:
	$(COMPOSE_CMD) build --no-cache
	$(COMPOSE_CMD) up -d

# Ensure terminal definition exists in the container
.PHONY: terminfo
terminfo:
	@if ! command -v infocmp >/dev/null 2>&1; then \
		echo "infocmp not found on host; install ncurses tools to enable terminfo import (may still work if container already has matching terminfo via ncurses-term)."; \
		exit 0; \
	fi
	infocmp -x "$$TERM" | $(COMPOSE_CMD) exec -T $(SERVICE) sh -lc 'tic -x -'

# Enter container in Zsh
.PHONY: shell
shell: terminfo
	$(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) zsh

# Enter container in tmux
.PHONY: tmux
tmux: terminfo
	$(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) tmux

# Open VS Code attached to the container
.PHONY: vscode
vscode:
	@cid=$$(docker ps -q -f name=^/dev_container_debian_13$$); \
	if [ -z "$$cid" ]; then \
		echo "Container dev_container_debian_13 is not running."; \
		exit 1; \
	fi; \
	code --folder-uri "vscode-remote://dev-container+$$cid/home/dev/dev_container"

# Start JupyterLab inside container and expose port from .env
.PHONY: jupyter
jupyter:
	$(COMPOSE_CMD) exec $(SERVICE) sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/jupyter-with-token.sh"

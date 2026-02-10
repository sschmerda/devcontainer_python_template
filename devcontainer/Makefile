# Variables
ifneq (,$(wildcard env-vars/.env))
  include env-vars/.env
  export
endif
ifneq (,$(wildcard env-vars/.env.secrets))
  include env-vars/.env.secrets
  export
endif

JUPYTER_PORT ?= 8888
COMPOSE_FILE=docker/docker-compose.yml
COMPOSE_DATA_FILE=docker/docker-compose.data.yml
# Must match the service name under `services:` in docker-compose.yml.
SERVICE=dev

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  UID_ARG := UID=$(shell id -u)
  GID_ARG := GID=$(shell id -g)
endif

COMPOSE_BASE_FILES = -f $(COMPOSE_FILE)
COMPOSE_DATA_FILES = -f $(COMPOSE_FILE) -f $(COMPOSE_DATA_FILE)

COMPOSE_CMD = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_BASE_FILES)
COMPOSE_CMD_DATA = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_DATA_FILES)

# Unified dev-env commands (latest)
.PHONY: up-dev-env
up-dev-env:
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) up -d --build

.PHONY: up-dev-env-data-mount
up-dev-env-data-mount:
	@if [ -z "$(strip $(HOST_DATA_DIR))" ]; then \
		echo "HOST_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
		exit 1; \
	fi
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD_DATA) up -d --build

.PHONY: rebuild-dev-env
rebuild-dev-env:
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) build --no-cache
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) up -d

.PHONY: rebuild-dev-env-data-mount
rebuild-dev-env-data-mount:
	@if [ -z "$(strip $(HOST_DATA_DIR))" ]; then \
		echo "HOST_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
		exit 1; \
	fi
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD_DATA) build --no-cache
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD_DATA) up -d

# Unified dev-env commands (locked)
.PHONY: up-dev-env-lock
up-dev-env-lock:
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) up -d --build

.PHONY: up-dev-env-lock-data-mount
up-dev-env-lock-data-mount:
	@if [ -z "$(strip $(HOST_DATA_DIR))" ]; then \
		echo "HOST_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
		exit 1; \
	fi
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD_DATA) up -d --build

.PHONY: rebuild-dev-env-lock
rebuild-dev-env-lock:
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) build --no-cache
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) up -d

.PHONY: rebuild-dev-env-lock-data-mount
rebuild-dev-env-lock-data-mount:
	@if [ -z "$(strip $(HOST_DATA_DIR))" ]; then \
		echo "HOST_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
		exit 1; \
	fi
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD_DATA) build --no-cache
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD_DATA) up -d

# Lock all dev environments (run inside container only)
.PHONY: lock-dev-env
lock-dev-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-mamba-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-r-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-latex-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-quarto-env.sh"

# Generate mamba lockfile (run inside container only)
.PHONY: lock-mamba-env
lock-mamba-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-mamba-env.sh"

# Generate R lockfile (run inside container only)
.PHONY: lock-r-env
lock-r-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-r-env.sh"

# Generate LaTeX lockfile (run inside container only)
.PHONY: lock-latex-env
lock-latex-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-latex-env.sh"

# Generate Quarto lockfile (run inside container only)
.PHONY: lock-quarto-env
lock-quarto-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-quarto-env.sh"

# Remove all lockfiles
.PHONY: clean-locks
clean-locks:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/python-environment/python-environment-lock.yml
	rm -f /home/dev/dev_container/devcontainer/r-environment/r-environment-lock.yml
	rm -f /home/dev/dev_container/devcontainer/latex-environment/latex-environment-lock.txt
	rm -f /home/dev/dev_container/devcontainer/quarto-environment/quarto-lock.env

# Remove Python lockfile
.PHONY: clean-lock-mamba
clean-lock-mamba:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/python-environment/python-environment-lock.yml

# Remove R lockfile
.PHONY: clean-lock-r
clean-lock-r:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/r-environment/r-environment-lock.yml

# Remove LaTeX lockfile
.PHONY: clean-lock-latex
clean-lock-latex:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/latex-environment/latex-environment-lock.txt

# Remove Quarto lockfile
.PHONY: clean-lock-quarto
clean-lock-quarto:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/quarto-environment/quarto-lock.env

# Ensure terminal definition exists in the container
.PHONY: terminfo
terminfo:
	@if ! command -v infocmp >/dev/null 2>&1; then \
		echo "infocmp not found on host; install ncurses tools to enable terminfo import (may still work if container already has matching terminfo via ncurses-term)."; \
		exit 0; \
	fi
	infocmp -x "$$TERM" | $(COMPOSE_CMD) exec -T $(SERVICE) sh -lc 'tic -x -'

# Export JupyterLab user settings to build-assets (run inside container only)
.PHONY: jupyter-settings-export
jupyter-settings-export:
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/export-jupyterlab-settings.sh"

# Restore JupyterLab user settings from build-assets (run inside container only)
.PHONY: jupyter-settings-restore
jupyter-settings-restore:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/restore-jupyterlab-settings.sh"

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
	$(COMPOSE_CMD) exec $(SERVICE) sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/run-jupyter-with-token.sh"

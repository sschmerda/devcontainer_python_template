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

# Unified dev-env commands (latest)
.PHONY: up-dev-env
up-dev-env:
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) up -d --build

.PHONY: rebuild-dev-env
rebuild-dev-env:
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) build --no-cache
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) up -d

# Unified dev-env commands (locked)
.PHONY: up-dev-env-lock
up-dev-env-lock:
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) up -d --build

.PHONY: rebuild-dev-env-lock
rebuild-dev-env-lock:
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) build --no-cache
	DEV_ENV_LOCKED=1 $(COMPOSE_CMD) up -d

# Lock all dev environments (run inside container only)
.PHONY: lock-dev-env
lock-dev-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-mamba-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-r-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-latex-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-quarto-env.sh"

# Generate mamba lockfile (run inside container only)
.PHONY: lock-mamba-env
lock-mamba-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-mamba-env.sh"

# Generate R lockfile (run inside container only)
.PHONY: lock-r-env
lock-r-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-r-env.sh"

# Generate LaTeX lockfile (run inside container only)
.PHONY: lock-latex-env
lock-latex-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-latex-env.sh"

# Generate Quarto lockfile (run inside container only)
.PHONY: lock-quarto-env
lock-quarto-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/lock-quarto-env.sh"

# Remove all lockfiles
.PHONY: clean-locks
clean-locks:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/mamba_environment/conda-lock.yml
	rm -f /home/dev/dev_container/devcontainer/r-environment/conda-lock.yml
	rm -f /home/dev/dev_container/devcontainer/latex-environment/texlive-repo.txt
	rm -f /home/dev/dev_container/devcontainer/quarto-environment/quarto-lock.env

# Remove Python lockfile
.PHONY: clean-lock-mamba
clean-lock-mamba:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/mamba_environment/conda-lock.yml

# Remove R lockfile
.PHONY: clean-lock-r
clean-lock-r:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/r-environment/conda-lock.yml

# Remove LaTeX lockfile
.PHONY: clean-lock-latex
clean-lock-latex:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	rm -f /home/dev/dev_container/devcontainer/latex-environment/texlive-repo.txt

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
	$(COMPOSE_CMD) exec $(SERVICE) sh -lc "sh /home/dev/dev_container/devcontainer/shell_scripts/run-jupyter-with-token.sh"

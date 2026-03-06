JUPYTER_PORT ?= 8888
COMPOSE_FILE=docker/docker-compose.yml
COMPOSE_DATA_FILE=docker/docker-compose.data.yml
COMPOSE_SERVICES_FILE=docker/docker-compose.services.yml
COMPOSE_SERVICES_LOCK_FILE=docker/docker-compose.services-lock.yml
COMPOSE_ENV_FILES=--env-file env-vars/.env --env-file env-vars/.env.secrets
OS_LOCK_ENV_FILE=os-environment/os-lock.env
OS_LOCK_ENV_FILE_ARG=$(if $(wildcard $(OS_LOCK_ENV_FILE)),--env-file $(OS_LOCK_ENV_FILE),)
LOCK_ENV_FILE_ARG=$(if $(wildcard services-environment/services-lock.env),--env-file services-environment/services-lock.env,)
FORCE ?= 0
# Must match the service name under `services:` in docker-compose.yml.
SERVICE=dev

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  UID_ARG := UID=$(shell id -u)
  GID_ARG := GID=$(shell id -g)
endif

COMPOSE_BASE_FILES = -f $(COMPOSE_FILE)
COMPOSE_DATA_FILES = -f $(COMPOSE_FILE) -f $(COMPOSE_DATA_FILE)
COMPOSE_SERVICES_FILES = -f $(COMPOSE_FILE) -f $(COMPOSE_SERVICES_FILE)
COMPOSE_SERVICES_LOCK_FILES = -f $(COMPOSE_FILE) -f $(COMPOSE_SERVICES_FILE) -f $(COMPOSE_SERVICES_LOCK_FILE)

COMPOSE_CMD = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_BASE_FILES)
COMPOSE_CMD_LOCK = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $(COMPOSE_BASE_FILES)
COMPOSE_CMD_SERVICES = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES)
COMPOSE_CMD_SERVICES_LOCK = $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $(LOCK_ENV_FILE_ARG) $(COMPOSE_SERVICES_LOCK_FILES)

define check_service_vars
	@set -a; \
	. env-vars/.env.secrets; \
	set +a; \
	services="$$(DEV_ENV_LOCKED=$(1) docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -z "$$services" ]; then \
		echo "No additional services are enabled in $(COMPOSE_SERVICES_FILE)."; \
		exit 0; \
	fi; \
	for svc in $$services; do \
		case "$$svc" in \
			postgres) \
				if [ -z "$$POSTGRES_DATA_DIR" ]; then \
					echo "POSTGRES_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				if [ -z "$$POSTGRES_PASSWORD" ]; then \
					echo "POSTGRES_PASSWORD is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			mysql) \
				if [ -z "$$MYSQL_DATA_DIR" ]; then \
					echo "MYSQL_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				if [ -z "$$MYSQL_ROOT_PASSWORD" ]; then \
					echo "MYSQL_ROOT_PASSWORD is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			elasticsearch) \
				if [ -z "$$ELASTICSEARCH_DATA_DIR" ]; then \
					echo "ELASTICSEARCH_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			redis) \
				if [ -z "$$REDIS_DATA_DIR" ]; then \
					echo "REDIS_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			minio) \
				if [ -z "$$MINIO_DATA_DIR" ]; then \
					echo "MINIO_DATA_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				if [ -z "$$MINIO_ROOT_USER" ]; then \
					echo "MINIO_ROOT_USER is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				if [ -z "$$MINIO_ROOT_PASSWORD" ]; then \
					echo "MINIO_ROOT_PASSWORD is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			nginx) \
				if [ -z "$$NGINX_CONF_DIR" ]; then \
					echo "NGINX_CONF_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			celery-worker|celery-beat|flower) \
				if [ -z "$$CELERY_CODE_DIR" ]; then \
					echo "CELERY_CODE_DIR is empty. Set it in devcontainer/env-vars/.env.secrets."; \
					exit 1; \
				fi; \
				;; \
			*) \
				echo "Unsupported enabled service in $(COMPOSE_SERVICES_FILE): $$svc"; \
				exit 1; \
				;; \
		esac; \
	done
endef

# Unified dev-env commands (latest)
.PHONY: up-dev-env-latest
up-dev-env-latest:
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $$compose_files up -d --build; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev up-dev-env-latest

.PHONY: rebuild-dev-env-latest
rebuild-dev-env-latest:
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $$compose_files build --no-cache; \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $$compose_files up -d; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev rebuild-dev-env-latest

# Unified dev-env commands (latest package resolution + locked OS base image)
.PHONY: up-dev-env-latest-os-lock
up-dev-env-latest-os-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files up -d --build; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev up-dev-env-latest-os-lock

.PHONY: rebuild-dev-env-latest-os-lock
rebuild-dev-env-latest-os-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files build --no-cache; \
	DEV_ENV_LOCKED=0 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files up -d; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev rebuild-dev-env-latest-os-lock

# Unified dev-env commands (locked)
.PHONY: up-dev-env-lock
up-dev-env-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=1 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files up -d --build; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=1 BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev up-dev-env-lock

.PHONY: rebuild-dev-env-lock
rebuild-dev-env-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	@set -e; \
	set -a; . env-vars/.env.secrets 2>/dev/null || true; set +a; \
	compose_files="$(COMPOSE_BASE_FILES)"; \
	if [ -n "$$HOST_DATA_DIR" ]; then \
		case "$$HOST_DATA_DIR" in /*) ;; *) echo "HOST_DATA_DIR must be an absolute path: $$HOST_DATA_DIR"; exit 1;; esac; \
		if [ ! -d "$$HOST_DATA_DIR" ]; then \
			echo "HOST_DATA_DIR does not exist: $$HOST_DATA_DIR"; \
			exit 1; \
		fi; \
		compose_files="$(COMPOSE_DATA_FILES)"; \
	fi; \
	started=$$(date +%s); \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=1 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files build --no-cache; \
	DEV_ENV_LOCKED=1 $(UID_ARG) $(GID_ARG) docker compose $(COMPOSE_ENV_FILES) $(OS_LOCK_ENV_FILE_ARG) $$compose_files up -d; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh os)"; \
	DEV_ENV_LOCKED=1 BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh dev rebuild-dev-env-lock

.PHONY: down-dev-env
down-dev-env:
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Stop and remove dev container now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_BASE_FILES) config --services | grep '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD) stop $$services; \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD) rm -f $$services; \
	fi

.PHONY: stop-dev-env
stop-dev-env:
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Stop dev container now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_BASE_FILES) config --services | grep '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD) stop $$services; \
	fi

# Lock all dev environments (run inside container only)
.PHONY: lock-dev-env-container
lock-dev-env-container:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update all dev lockfiles now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-micromamba-env.sh"
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-additional-binaries-env.sh"
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-tooling-config-env.sh"
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-dotfiles-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-python-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-flower-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-r-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-latex-env.sh"
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-quarto-env.sh"

# Lock base OS image digest used for Dockerfile FROM (run on host).
.PHONY: lock-os-image-host
lock-os-image-host:
	@if [ -f /.dockerenv ]; then \
		echo "This target must be run on the host."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update OS image lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh shell-scripts/lock-os-image.sh

# Lock dev env from host by orchestrating OS lock + build + in-container lock.
.PHONY: lock-dev-env
lock-dev-env:
	@if [ -f /.dockerenv ]; then \
		echo "This target must be run on the host."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Run host lock pipeline now (lock OS + rebuild latest with OS lock + dev lock + cleanup)? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@$(MAKE) lock-os-image-host FORCE=$(FORCE)
	@$(MAKE) rebuild-dev-env-latest-os-lock FORCE=1
	@DEV_ENV_LOCKED=0 $(COMPOSE_CMD) exec -T $(SERVICE) sh -lc "cd /home/dev/dev_container/devcontainer && make lock-dev-env-container FORCE=1"
	@set -e; \
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) stop $(SERVICE) >/dev/null 2>&1 || true; \
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) rm -f $(SERVICE) >/dev/null 2>&1 || true; \
	image_id="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_BASE_FILES) images -q $(SERVICE) | head -n 1)"; \
	if [ -n "$$image_id" ]; then docker image rm "$$image_id" >/dev/null 2>&1 || true; fi

# Lock dev env from host and rebuild from lockfiles.
.PHONY: lock-dev-env-and-rebuild
lock-dev-env-and-rebuild:
	@if [ -f /.dockerenv ]; then \
		echo "This target must be run on the host."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Run lock pipeline and rebuild from lock now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@$(MAKE) lock-dev-env FORCE=1
	@$(MAKE) rebuild-dev-env-lock FORCE=1

# Generate additional binaries lockfile (run inside container only)
.PHONY: lock-additional-binaries-env
lock-additional-binaries-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update additional binaries lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-additional-binaries-env.sh"

# Generate micromamba lockfile (run inside container only)
.PHONY: lock-micromamba-env
lock-micromamba-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update micromamba lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-micromamba-env.sh"

# Generate tooling config lockfile (run inside container only)
.PHONY: lock-tooling-config-env
lock-tooling-config-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update tooling config lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-tooling-config-env.sh"

# Generate dotfiles lockfile (run inside container only)
.PHONY: lock-dotfiles-env
lock-dotfiles-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update dotfiles lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "bash /home/dev/dev_container/devcontainer/shell-scripts/lock-dotfiles-env.sh"

# Generate Python lockfile (run inside container only)
.PHONY: lock-python-env
lock-python-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update Python lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-python-env.sh"

# Generate R lockfile (run inside container only)
.PHONY: lock-r-env
lock-r-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update R lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-r-env.sh"

# Generate LaTeX lockfile (run inside container only)
.PHONY: lock-latex-env
lock-latex-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update LaTeX lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-latex-env.sh"

# Generate Quarto lockfile (run inside container only)
.PHONY: lock-quarto-env
lock-quarto-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update Quarto lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-quarto-env.sh"

# Generate Flower lockfile from Python lockfile (run inside container only)
.PHONY: lock-flower-env
lock-flower-env:
	@if [ ! -f /.dockerenv ]; then \
		echo "This target must be run inside the container."; \
		exit 1; \
	fi
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update Flower lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/lock-flower-env.sh"

# Remove all lockfiles
.PHONY: clean-lock-all
clean-lock-all:
	rm -f python-environment/python-environment-lock.yml
	rm -f r-environment/r-environment-lock.yml
	rm -f latex-environment/latex-environment-lock.txt
	rm -f quarto-environment/quarto-lock.env
	rm -f micromamba-environment/micromamba-lock.env
	rm -f additional-binaries-environment/additional-binaries-lock.env
	rm -f tooling-config-environment/tooling-config-lock.env
	rm -f dotfiles-environment/dotfiles-lock.env
	rm -f os-environment/os-lock.env
	rm -f services-environment/flower/flower-environment-lock.yml
	rm -f services-environment/services-lock.env

# Remove Python lockfile
.PHONY: clean-lock-python
clean-lock-python:
	rm -f python-environment/python-environment-lock.yml

# Remove R lockfile
.PHONY: clean-lock-r
clean-lock-r:
	rm -f r-environment/r-environment-lock.yml

# Remove LaTeX lockfile
.PHONY: clean-lock-latex
clean-lock-latex:
	rm -f latex-environment/latex-environment-lock.txt

# Remove Quarto lockfile
.PHONY: clean-lock-quarto
clean-lock-quarto:
	rm -f quarto-environment/quarto-lock.env

# Remove micromamba lockfile
.PHONY: clean-lock-micromamba
clean-lock-micromamba:
	rm -f micromamba-environment/micromamba-lock.env

# Remove additional binaries lockfile
.PHONY: clean-lock-additional-binaries
clean-lock-additional-binaries:
	rm -f additional-binaries-environment/additional-binaries-lock.env

# Remove tooling config lockfile
.PHONY: clean-lock-tooling-config
clean-lock-tooling-config:
	rm -f tooling-config-environment/tooling-config-lock.env

# Remove dotfiles lockfile
.PHONY: clean-lock-dotfiles
clean-lock-dotfiles:
	rm -f dotfiles-environment/dotfiles-lock.env

.PHONY: clean-lock-os-image
clean-lock-os-image:
	rm -f os-environment/os-lock.env

# Remove Flower lockfile
.PHONY: clean-lock-flower
clean-lock-flower:
	rm -f services-environment/flower/flower-environment-lock.yml

# Ensure terminal definition exists in the container
.PHONY: terminfo
terminfo:
	@if ! command -v infocmp >/dev/null 2>&1; then \
		echo "infocmp not found on host; install ncurses tools to enable terminfo import (may still work if container already has matching terminfo via ncurses-term)."; \
		exit 0; \
	fi
	infocmp -x "$$TERM" | DEV_ENV_LOCKED=0 $(COMPOSE_CMD) exec -T $(SERVICE) sh -lc 'tic -x -'

.PHONY: clean-build-metadata
clean-build-metadata:
	rm -f build-metadata/*.log

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
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) zsh

# Enter container in tmux
.PHONY: tmux
tmux: terminfo
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) exec -e TERM -e COLORTERM $(SERVICE) tmux

# Open VS Code and manually connect to the container
.PHONY: vscode
vscode:
	code .

# Start JupyterLab inside container and expose port from .env
.PHONY: jupyter
jupyter:
	DEV_ENV_LOCKED=0 $(COMPOSE_CMD) exec $(SERVICE) sh -lc "sh /home/dev/dev_container/devcontainer/shell-scripts/run-jupyter-with-token.sh"

# Additional services lifecycle (latest)
.PHONY: up-services-latest
up-services-latest:
	$(call check_service_vars,0)
	@set -e; \
	started=$$(date +%s); \
	services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) pull --ignore-buildable $$services; \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) up -d --build $$services; \
	fi; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh services up-services-latest

.PHONY: rebuild-services-latest
rebuild-services-latest:
	$(call check_service_vars,0)
	@set -e; \
	started=$$(date +%s); \
	services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) pull --ignore-buildable $$services; \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) up -d --build --force-recreate $$services; \
	fi; \
	BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh services rebuild-services-latest

# Additional services lifecycle (locked)
.PHONY: up-services-lock
up-services-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	$(call check_service_vars,1)
	@set -e; \
	started=$$(date +%s); \
	services="$$(DEV_ENV_LOCKED=1 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		ACTIVE_SERVICES="$$services" sh -lc "sh shell-scripts/lock-services-env.sh validate"; \
		eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh all)"; \
		DEV_ENV_LOCKED=1 $(COMPOSE_CMD_SERVICES_LOCK) pull --ignore-buildable $$services; \
		DEV_ENV_LOCKED=1 $(COMPOSE_CMD_SERVICES_LOCK) up -d --build $$services; \
	fi; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh all)"; \
	DEV_ENV_LOCKED=1 BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh services up-services-lock

.PHONY: rebuild-services-lock
rebuild-services-lock:
	@if [ ! -f "$(OS_LOCK_ENV_FILE)" ]; then \
		echo "Missing $(OS_LOCK_ENV_FILE). Run make lock-os-image-host first."; \
		exit 1; \
	fi
	$(call check_service_vars,1)
	@set -e; \
	started=$$(date +%s); \
	services="$$(DEV_ENV_LOCKED=1 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		ACTIVE_SERVICES="$$services" sh -lc "sh shell-scripts/lock-services-env.sh validate"; \
		eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh all)"; \
		DEV_ENV_LOCKED=1 $(COMPOSE_CMD_SERVICES_LOCK) pull --ignore-buildable $$services; \
		DEV_ENV_LOCKED=1 $(COMPOSE_CMD_SERVICES_LOCK) up -d --build --force-recreate $$services; \
	fi; \
	eval "$$(sh shell-scripts/export-cross-platform-lock-vars.sh all)"; \
	DEV_ENV_LOCKED=1 BUILD_DURATION_SECONDS=$$(( $$(date +%s) - $$started )) sh shell-scripts/record-build-metadata.sh services rebuild-services-lock

.PHONY: down-services
down-services:
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Stop and remove additional services now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) stop $$services; \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) rm -f $$services; \
	fi

.PHONY: stop-services
stop-services:
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Stop additional services now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		DEV_ENV_LOCKED=0 $(COMPOSE_CMD_SERVICES) stop $$services; \
	fi

.PHONY: lock-services
lock-services:
	@sh -lc 'if [ "$(FORCE)" != "1" ]; then \
		printf "Update services lockfile now? [y/N] "; \
		read -r ans; \
		case "$$ans" in y|Y) ;; *) echo "Aborted."; exit 1;; esac; \
	fi'
	@services="$$(DEV_ENV_LOCKED=0 docker compose $(COMPOSE_ENV_FILES) $(COMPOSE_SERVICES_FILES) config --services | grep -v '^$(SERVICE)$$')"; \
	if [ -n "$$services" ]; then \
		ACTIVE_SERVICES="$$services" sh -lc "sh shell-scripts/lock-services-env.sh"; \
	fi

.PHONY: clean-lock-services
clean-lock-services:
	rm -f services-environment/services-lock.env

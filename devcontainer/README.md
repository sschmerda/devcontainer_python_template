# Readme

## Readme structure

Use this order when reading/configuring the template:

- 1. Create new repo from template
- 2. Make commands
- 3. Build metadata
- 4. .env configuration
- 5. .env.secrets
- 6. Environment variable loading model
- 7. Development vs production secrets
- 8. Host data mount
- 9. Python and R version pins
- 10. python-environment
- 11. R packages
- 12. LaTeX packages
- 13. Quarto
- 14. JupyterLab settings
- 15. Additional services
- 16. Web applications (FastAPI/Flask/Django)
- 17. Locked vs latest builds
- 18. Template repo setup

## Create new repo from template

```bash
  gh repo create <your-org-or-user>/<new-repo-name> \
    --template <your-org-or-user>/<devcontainer-template-repo> \
    --description "My new project based on the devcontainer template" \
    --gitignore Python \
    --public \
    --clone
```

## Make commands

Run these from the `devcontainer` directory:

- `make up-dev-env`: Build and start using latest package definitions.
- `make up-dev-env-data-mount`: Build/start latest env with external host data mount.
- `make rebuild-dev-env`: Rebuild using latest package definitions.
- `make rebuild-dev-env-data-mount`: Rebuild/start latest env with external host data mount.
- `make up-dev-env-lock`: Build and start using lockfiles when present.
- `make up-dev-env-lock-data-mount`: Build/start locked env with external host data mount.
- `make rebuild-dev-env-lock`: Rebuild using lockfiles when present.
- `make rebuild-dev-env-lock-data-mount`: Rebuild/start locked env with external host data mount.
- `make stop-dev-env`: Stop the main dev container service without removing it.
- `make down-dev-env`: Stop and remove the main dev container service.
- `make shell`: Open a shell in the container.
- `make tmux`: Open tmux in the container.
- `make vscode`: Open VS Code for this repo (then "Reopen in Container").
- `make jupyter`: Start JupyterLab inside the container.
- Quarto live preview: `quarto preview <file>.qmd --host 0.0.0.0 --port ${QUARTO_PORT:-4200}`.
- `make lock-dev-env`: Generate lockfiles for Python, R, LaTeX, and Quarto (run inside the container).
- `make up-services`: Pull and start configured additional services (latest mode).
- `make rebuild-services`: Re-pull and recreate configured additional services (latest mode).
- `make up-services-lock`: Pull and start configured additional services using locked image digests.
- `make rebuild-services-lock`: Re-pull and recreate configured additional services using locked image digests.
- `make stop-services`: Stop configured additional services without removing them.
- `make down-services`: Stop and remove configured additional services.
- `make lock-services`: Generate `devcontainer/services-environment/services-lock.env` from current service images.
- `make jupyter-settings-export`: Export JupyterLab user settings to `devcontainer/build-assets/` (run inside the container).
- `make jupyter-settings-restore`: Restore JupyterLab user settings from `devcontainer/build-assets/` (run inside the container).

## Build metadata

Build metadata is recorded automatically for every `up-*` and `rebuild-*` dev/services target.

- Dev env non-lock metadata: `devcontainer/build-metadata/dev-env-builds-non-lock.log`
- Dev env lock metadata: `devcontainer/build-metadata/dev-env-builds-lock.log`
- Services non-lock metadata: `devcontainer/build-metadata/services-builds-non-lock.log`
- Services lock metadata: `devcontainer/build-metadata/services-builds-lock.log`

Behavior:

- Each run writes exactly one file, chosen by scope (`dev`/`services`) and mode (`DEV_ENV_LOCKED=0/1`).
- Keys are mode-agnostic (same key names in all four files) and overwritten on each run.

Captured fields include:

- UTC timestamp, command name, and build duration
- Host OS/kernel/architecture/CPU/RAM
- Docker client/server/compose versions and Docker context
- Dev logs use singular keys: `SERVICE_NAME`, `IMAGE_NAME`, `IMAGE_SIZE`, `CONTAINER_NAME`, `CONTAINER_SIZE`
- Services logs use plural keys: `SERVICE_NAMES`, `IMAGE_NAMES`, `IMAGE_SIZES`, `CONTAINER_NAMES`, `CONTAINER_SIZES`
- Data mount flag (`DATA_MOUNT_USED`: `true` when a relevant bind mount is used, otherwise `false`)

## .env configuration

Non-secret configuration values live in `devcontainer/env-vars/.env`.

Common variables:

- `JUPYTER_PORT`: Port to expose JupyterLab (default: `8888`).
- `QUARTO_PORT`: Port to expose Quarto live preview (default: `4200`).
- `TZ`: Container timezone (default: `UTC`).
- `UID`: Host user id for file ownership (default: `1000`).
- `GID`: Host group id for file ownership (default: `1000`).
- `RETRY_ATTEMPTS`: Number of retry attempts for micromamba/conda-lock install commands during Python/R environment creation (default: `4`).
- `RETRY_DELAY_SECONDS`: Base delay in seconds for retries; each retry sleeps `base_delay * attempt` (default: `10`).
- `HOST_DATA_READ_ONLY`: Host data mount mode when `HOST_DATA_DIR` is set (`true` = read-only, `false` = read-write; default: `true`).
- `HOST_DATA_MOUNT_PATH`: Container mount path for `HOST_DATA_DIR` when using `*-data-mount` targets.
- `HOST_DATA_SYMLINK_PATH`: Symlink created in the container pointing to `HOST_DATA_MOUNT_PATH`.
- `POSTGRES_*`: Active default service settings for local PostgreSQL (image, container name, port, db, user).
- `MYSQL_*`, `REDIS_*`, `NGINX_*`, `CELERY_*`, `FLOWER_*`: Optional service templates (commented by default).

## .env.secrets

Secret configuration values live in `devcontainer/env-vars/.env.secrets`.
This file is committed as a template (keys only, empty values).
Set values locally on each machine.
For `HOST_DATA_DIR`, use an absolute path without spaces and without quotation marks.
For service data paths (`*_DATA_DIR`), also use absolute paths without quotes.

## Environment variable loading model

Environment variables are now loaded by Docker Compose directly from:

- `devcontainer/env-vars/.env`
- `devcontainer/env-vars/.env.secrets`

The Makefile no longer acts as the primary env-variable source of truth.
It calls Docker Compose with explicit `--env-file` flags, so variable resolution is consistent across:

- `docker-compose.yml`
- `docker-compose.data.yml`
- `docker-compose.services.yml`
- `docker-compose.services-lock.yml`

Notes:

- Commented variables are not loaded.
- Unset variables resolve to empty values unless you enforce checks.
- Service validation checks in `make up-services*` still fail early for required paths/passwords.
- `build.args` are available only at image build time; values from `env_file` are runtime environment variables inside running containers.

## Development vs production secrets

Development (this repo):

- Secrets are stored in `devcontainer/env-vars/.env.secrets` on the local machine.
- Compose passes those values to containers as environment variables.
- This is acceptable for local development and smoke tests.

Production (recommended):

- Do not keep secrets in repo-managed env files.
- Use a secret manager or Docker/Kubernetes secrets.
- Inject only the secrets each service needs, with least-privilege scope.

## Host data mount

External host data is optional and controlled by `HOST_DATA_DIR` in `devcontainer/env-vars/.env.secrets`.

- Data mounting is enabled only when using `*-data-mount` Make targets.
- If `HOST_DATA_DIR` is set and a `*-data-mount` target is used, Docker Compose adds a bind mount:
  - host: `HOST_DATA_DIR`
  - container: `HOST_DATA_MOUNT_PATH`
  - mode: controlled by `HOST_DATA_READ_ONLY` in `devcontainer/env-vars/.env`
- On container startup, a symlink is created:
  - `HOST_DATA_SYMLINK_PATH -> HOST_DATA_MOUNT_PATH`
- If `HOST_DATA_DIR` is empty, `*-data-mount` targets fail early and the symlink is removed/not created.
- `HOST_DATA_DIR=` (key present but empty value) is treated as unset for data mounts; no host data bind mount is created.

## Python and R version pins

Python and R runtime versions are explicitly pinned in environment files (not via `.env` variables):

- Set Python version in `devcontainer/python-environment/python-environment.yml` (`python=...`).
- Set R version in `devcontainer/r-environment/r-environment.yml` (`r-base=...`).
- Keep `devcontainer/services-environment/flower/flower-environment.yml` on the same Python major/minor version as `devcontainer/python-environment/python-environment.yml`.

## python-environment

Mamba environment specs live in `devcontainer/python-environment/`:

- `python-environment.yml`: Source of truth for package selection.
- `python-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-python-env` or `make lock-dev-env` to create it).

Python is installed in a separate micromamba environment named `python-env`.

Note: `conda-lock` handling is driven by the lock scripts. Keep the lock tooling/version behavior in sync with `devcontainer/shell-scripts/lock-python-env.sh` if you change the workflow.

## R packages

R environment specs live in `devcontainer/r-environment/`:

- `r-environment.yml`: Source of truth for package selection.
- `r-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-r-env` or `make lock-dev-env` to create it).

R is installed in a separate micromamba environment named `r-env`.

## LaTeX packages

Additional LaTeX packages are managed via `devcontainer/latex-environment/latex-packages.txt` and installed during the image build by `devcontainer/shell-scripts/install-latex-packages.sh`. Uncomment the packages you need and rebuild the image.
TinyTeX itself is installed via `devcontainer/shell-scripts/install-tinytex.sh` using a temporary micromamba installer environment (`tinytex-installer`), so `r-env` remains focused on analysis packages.

## Quarto

Quarto is installed user-local from GitHub release tarballs (not from conda):

- Non-lock builds install the latest stable release (`releases/latest`).
- Lock builds install the exact version and architecture URL stored in `devcontainer/quarto-environment/quarto-lock.env`.
- Lock generation validates both Linux assets (`amd64` and `arm64`) so the same lockfile works across chips.

## JupyterLab settings

If you want to persist your custom settings, export them with `make jupyter-settings-export` (inside the container). The archive is stored in `devcontainer/build-assets/jupyterlab-user-settings.tar.gz` and restored at build time by `devcontainer/shell-scripts/restore-jupyterlab-settings.sh`.

## Additional services

Additional local services are configured via:

- `devcontainer/docker/docker-compose.services.yml`
- `devcontainer/docker/docker-compose.services-lock.yml`
- `devcontainer/services-environment/services-lock.env`

When adding or enabling a service, update these files in this order:

- `devcontainer/docker/docker-compose.services.yml`: uncomment/enable the service here first (primary switch).
- `devcontainer/docker/docker-compose.services-lock.yml`: for pull-based services, keep the same service uncommented here for lock mode.
- `devcontainer/env-vars/.env`: set or uncomment non-secret variables (image, host, ports, container name, commands).
- `devcontainer/env-vars/.env.secrets`: set secrets and absolute host paths (`*_PASSWORD`, `*_DATA_DIR`, config/code paths).

After enabling a service:

- run `make lock-services` to refresh digest locks for active pull-based services.
- run `make rebuild-services` (latest mode) or `make rebuild-services-lock` (lock mode).

Current default:

- All additional services are commented out by default in `devcontainer/docker/docker-compose.services.yml`.
- Enable only the services required for your current project.

Service overview:

- `postgres`: Primary relational database service for local app development and SQL testing.
- `mysql` (commented): Optional second relational database service for MySQL-specific compatibility checks.
- `elasticsearch` (commented): Search-oriented document database for full-text indexing and retrieval.
- `redis`: In-memory data store used as Celery broker/result backend and for cache-style workflows.
- `minio` (commented): S3-compatible object storage service for binary/file data in local development.
- `nginx`: Reverse proxy/static-file front-end for local routing and production-like ingress simulation.
- `celery-worker`: Executes asynchronous background jobs from the queue.
- `celery-beat`: Scheduler that enqueues periodic jobs (cron-like behavior) for Celery.
- `flower`: Web UI to monitor Celery workers, queues, and task states.

Celery image behavior:

- `celery-worker` and `celery-beat` use `devcontainer/services-environment/celery/Dockerfile` with full `python-env` from:
  - `DEV_ENV_LOCKED=0` -> `python-environment/python-environment.yml`
  - `DEV_ENV_LOCKED=1` -> `python-environment/python-environment-lock.yml`
- `flower` uses `devcontainer/services-environment/flower/Dockerfile` with minimal `celery-env` from:
  - `DEV_ENV_LOCKED=0` -> `services-environment/flower/flower-environment.yml`
  - `DEV_ENV_LOCKED=1` -> `services-environment/flower/flower-environment-lock.yml`
- `make up-services` / `make rebuild-services` build Celery with `DEV_ENV_LOCKED=0`.
- `make up-services-lock` / `make rebuild-services-lock` build Celery with `DEV_ENV_LOCKED=1`.

Locking behavior:

- Non-lock service commands use the image tags from `devcontainer/env-vars/.env` (e.g. `postgres:latest`).
- `make lock-services` resolves and stores immutable digests in `devcontainer/services-environment/services-lock.env`.
- Lock service commands use those stored digests.
- Service commands automatically target all uncommented services in `devcontainer/docker/docker-compose.services.yml` (excluding the `dev` container).
- Build-based services (`celery-worker`, `celery-beat`, `flower`) are not digest-locked by `make lock-services`.
- Keep `devcontainer/docker/docker-compose.services-lock.yml` aligned with `devcontainer/docker/docker-compose.services.yml` for pull-based services:
  - If a service is commented in `docker-compose.services.yml`, keep it commented in `docker-compose.services-lock.yml`.
  - If a lock entry is enabled but its `*_IMAGE_LOCK` key is absent in `services-lock.env`, lock rebuilds fail (example: `MYSQL_IMAGE_LOCK` unset while `mysql` lock entry is enabled).

Minimal enable workflow:

1. Uncomment the service in `devcontainer/docker/docker-compose.services.yml`.
2. For pull-based services, uncomment the matching lock override in `devcontainer/docker/docker-compose.services-lock.yml`.
3. Set required non-secret vars in `devcontainer/env-vars/.env` and required secrets/paths in `devcontainer/env-vars/.env.secrets`.
4. Run `make lock-services` to refresh `devcontainer/services-environment/services-lock.env`.
5. Run `make rebuild-services` (latest mode) or `make rebuild-services-lock` (lock mode).

Lock verification:

- Render non-lock images:
  - `docker compose --env-file env-vars/.env --env-file env-vars/.env.secrets -f docker/docker-compose.yml -f docker/docker-compose.services.yml config | rg 'image:'`
- Render lock images:
  - `DEV_ENV_LOCKED=1 docker compose --env-file env-vars/.env --env-file env-vars/.env.secrets --env-file services-environment/services-lock.env -f docker/docker-compose.yml -f docker/docker-compose.services.yml -f docker/docker-compose.services-lock.yml config | rg 'image:'`
- Verify running pull-based services use digest refs:
  - `docker inspect dev_postgres --format '{{.Config.Image}}'`
  - `docker inspect dev_redis --format '{{.Config.Image}}'`
  - `docker inspect dev_nginx --format '{{.Config.Image}}'`

Recommended config mount location:

- `devcontainer/services-environment/nginx/` stores Nginx service config files.
- Use absolute host paths in `devcontainer/env-vars/.env.secrets` for `*_CONFIG_DIR`.

## Web applications (FastAPI/Flask/Django)

For local web-app development, the same service pattern works for FastAPI, Flask, and Django.

Recommended service usage:

- Base app only: no extra service required.
- App + SQL database: enable `postgres` or `mysql`.
- App + text search: enable `elasticsearch`.
- App + object/file storage: enable `minio`.
- App + async background jobs: enable `redis` + `celery-worker` (+ `celery-beat` for scheduled jobs).
- Task monitoring: enable `flower`.
- Reverse proxy/static serving/TLS simulation: enable `nginx`.

Environment variables to set for common web workflows:

- App port: `WEB_APP_PORT` (used as generic dev app port in this template).
- Postgres: `POSTGRES_*` in `.env` and `POSTGRES_PASSWORD`, `POSTGRES_DATA_DIR` in `.env.secrets`.
- MySQL: `MYSQL_*` in `.env` and `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_DATA_DIR` in `.env.secrets`.
- Redis: `REDIS_*` in `.env` and `REDIS_DATA_DIR` in `.env.secrets`.
- Elasticsearch: `ELASTICSEARCH_*` in `.env` and `ELASTICSEARCH_DATA_DIR` in `.env.secrets`.
- MinIO: `MINIO_*` in `.env` and `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_DATA_DIR` in `.env.secrets`.
- Nginx: `NGINX_*` in `.env` and `NGINX_CONF_DIR` in `.env.secrets`.
- Celery/Flower: `CELERY_*`, `FLOWER_*` in `.env` and `CELERY_CODE_DIR` in `.env.secrets`.

Generic app start commands (inside the dev container, from your app directory):

- FastAPI (Uvicorn): `uvicorn main:app --host 0.0.0.0 --port ${WEB_APP_PORT} --reload`
- Flask: `flask run --host=0.0.0.0 --port=${WEB_APP_PORT} --debug`
- Django: `python manage.py runserver 0.0.0.0:${WEB_APP_PORT}`

Host access:

- Direct app access: `http://localhost:${WEB_APP_PORT}`
- If Nginx is enabled: use `http://localhost:${NGINX_HTTP_PORT}` (and `https://localhost:${NGINX_HTTPS_PORT}` if TLS is configured).

Note:

- The sample app in `workspace/` is for smoke-testing only; you can replace/remove it before committing project code.

## Locked vs latest builds

Use the unified targets for reproducible builds:

- `make up-dev-env` / `make rebuild-dev-env` installs the latest Python/R/LaTeX packages (selected by `DEV_ENV_LOCKED=0`).
- `make up-dev-env-lock` / `make rebuild-dev-env-lock` installs from lockfiles (`DEV_ENV_LOCKED=1`).
- `make lock-dev-env` generates/updates lockfiles for Python (conda-lock), R (conda-lock), LaTeX (TeX Live repository), and Quarto (GitHub release URLs).

Fallback behavior:

- If a Python/R/LaTeX lockfile is missing or invalid, the build falls back to the latest package list for that language.
- If both a lockfile and the latest package list are missing, the installer skips that language instead of failing.
- Python uses `python-environment/python-environment.yml` for latest and `python-environment/python-environment-lock.yml` for locked installs.
- R uses `r-environment/r-environment.yml` for latest and `r-environment/r-environment-lock.yml` for locked installs.
- LaTeX uses `latex-environment/latex-packages.txt` for latest and `latex-environment/latex-environment-lock.txt` for locked installs.
- Quarto uses GitHub latest for non-lock and `quarto-environment/quarto-lock.env` for lock; lock mode is strict (no fallback).

Locking guidance:

- For reproducibility, run `make lock-dev-env` immediately after installing/updating packages.
- After locking, prefer `make up-dev-env-lock` / `make rebuild-dev-env-lock` for consistent rebuilds.
- Run `make lock-dev-env` and language-specific `make lock-<env>` targets inside the dev container.
- Run `make lock-services` from the host in the `devcontainer/` directory.
- All `lock-*` targets ask for confirmation before writing lockfiles.
- Use `FORCE=1` to skip confirmation (useful for CI/non-interactive runs), e.g. `make lock-python-env FORCE=1`.
- `stop-*` and `down-*` targets also ask for confirmation.
- Use `FORCE=1` there as well, e.g. `make down-services FORCE=1`.

Individual lock targets:

- `make lock-python-env` updates `devcontainer/python-environment/python-environment-lock.yml`
- `make lock-flower-env` updates `devcontainer/services-environment/flower/flower-environment-lock.yml` via `conda-lock` for `linux-64` and `linux-aarch64`
- `make lock-r-env` updates `devcontainer/r-environment/r-environment-lock.yml`
- `make lock-latex-env` updates `devcontainer/latex-environment/latex-environment-lock.txt`
- `make lock-quarto-env` updates `devcontainer/quarto-environment/quarto-lock.env`

Locked installs are handled by:

- Python: `devcontainer/shell-scripts/install-python-packages-lock.sh`
- R: `devcontainer/shell-scripts/install-r-packages-lock.sh`
- LaTeX: `devcontainer/shell-scripts/install-latex-packages-lock.sh`
- Quarto: `devcontainer/shell-scripts/install-quarto-lock.sh`

Clean lock targets (run inside container):

- `make clean-locks`
- `make clean-lock-python`
- `make clean-lock-r`
- `make clean-lock-latex`
- `make clean-lock-quarto`
- `make clean-lock-flower`

## Template repo setup

When creating a new repo from this template, edit `devcontainer/env-vars/.env.secrets`
and set local values for the keys you need (for example `HOST_DATA_DIR`).

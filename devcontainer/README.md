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
- 14. Micromamba
- 15. OS base image lock
- 16. JupyterLab settings
- 17. Additional services
- 18. Web applications (FastAPI/Flask/Django)
- 19. Locked vs latest builds
- 20. Template repo setup

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

- `make up-dev-env-latest`: Build and start using latest package definitions.
- `make rebuild-dev-env-latest`: Rebuild using latest package definitions.
- `make up-dev-env-latest-os-lock`: Build/start with latest package definitions but locked OS image and locked base binaries (host lockfiles required).
- `make rebuild-dev-env-latest-os-lock`: Rebuild/start with latest package definitions but locked OS image and locked base binaries (host lockfiles required).
- `make up-dev-env-lock`: Build and start using lockfiles when present.
- `make rebuild-dev-env-lock`: Rebuild using lockfiles when present.
- `make stop-dev-env`: Stop the main dev container service without removing it.
- `make down-dev-env`: Stop and remove the main dev container service.
- `make shell`: Open a shell in the container.
- `make host-tmux`: Open a host tmux session whose windows enter the container shell.
- `make container-tmux`: Open tmux inside the container.
- `make vscode`: Open VS Code for this repo (then "Reopen in Container").
- `make jupyter`: Start JupyterLab inside the container.
- Quarto live preview: `quarto preview <file>.qmd --host 0.0.0.0 --port ${QUARTO_PORT}`.
- `make lock-dev-env-container`: Generate lockfiles for micromamba, additional binaries, user tooling repos, dotfiles repo ref, Python, R, LaTeX, and Quarto (run inside the container).
- `make lock-tooling-config-env`: Generate `devcontainer/tooling-config-environment/tooling-config-lock.env` for oh-my-zsh, zsh plugins/theme, and tmux TPM repos.
- `make lock-dotfiles-env`: Generate `devcontainer/dotfiles-environment/dotfiles-lock.env` with a pinned dotfiles commit.
- `make lock-os-image-host`: Generate `devcontainer/os-environment/os-lock.env` from `DEVCONTAINER_OS_IMAGE` (run on host).
- `make lock-base-binaries-host`: Generate `devcontainer/base-binaries-environment/base-binaries-lock.env` from the locked OS image (run on host).
- `make lock-dev-env-host`: Host lock step for OS image + base binaries.
- `make lock-dev-env`: Host lock pipeline (`lock-dev-env-host` + latest rebuild with host locks + in-container dev lock + cleanup).
- `make lock-dev-env-and-rebuild`: Host lock pipeline plus rebuild from lockfiles.
- `make up-services-latest`: Pull and start configured additional services (latest mode).
- `make rebuild-services-latest`: Re-pull and recreate configured additional services (latest mode).
- `make up-services-lock`: Pull and start configured additional services using locked image digests.
- `make rebuild-services-lock`: Re-pull and recreate configured additional services using locked image digests.
- `make stop-services`: Stop configured additional services without removing them.
- `make down-services`: Stop and remove configured additional services.
- `make lock-services`: Generate `devcontainer/services-environment/services-lock.env` from current service images and refresh the Flower environment lock (requires the dev container to be running).
- `make clean-build-metadata`: Remove all metadata log files from `devcontainer/build-metadata/`.
- `make jupyter-settings-export`: Export JupyterLab user settings to `devcontainer/build-assets/` (run inside the container).
- `make jupyter-settings-restore`: Restore JupyterLab user settings from `devcontainer/build-assets/` (run inside the container).

Where to run lock commands:

- Host: `make lock-os-image-host`, `make lock-base-binaries-host`, `make lock-dev-env-host`, `make lock-dev-env`, `make lock-dev-env-and-rebuild`, `make lock-services`
- Container: `make lock-dev-env-container` and individual env lock targets (`lock-python-env`, `lock-r-env`, `lock-latex-env`, `lock-quarto-env`, `lock-micromamba-env`, `lock-additional-binaries-env`, `lock-tooling-config-env`, `lock-dotfiles-env`, `lock-flower-env`)

Data-mount behavior for dev targets:

- If `HOST_DATA_DIR` is set, dev targets auto-include `docker-compose.data.yml`.
- If `HOST_DATA_DIR` is empty, dev targets run without host data mount.
- If `HOST_DATA_DIR` is set but invalid (non-absolute or missing directory), dev targets fail fast.

## Build metadata

Build metadata is recorded automatically for every `up-*` and `rebuild-*` dev/services target.

- Dev env latest metadata: `devcontainer/build-metadata/dev-env-builds-latest.log`
- Dev env lock metadata: `devcontainer/build-metadata/dev-env-builds-lock.log`
- Services latest metadata: `devcontainer/build-metadata/services-builds-latest.log`
- Services lock metadata: `devcontainer/build-metadata/services-builds-lock.log`

Behavior:

- Each run writes exactly one file, chosen by scope (`dev`/`services`) and mode (`DEV_ENV_LOCKED=0/1`).
- Keys are mode-agnostic (same key names in all four files) and overwritten on each run.

Captured fields include:

- UTC timestamp, command name, and build duration
- Host OS/kernel/architecture/CPU/RAM
- Docker client/server/compose versions and Docker context
- Host Make version (`MAKE_VERSION`)
- Dev logs use singular keys: `SERVICE_NAME`, `IMAGE_NAME`, `IMAGE_SIZE`, `CONTAINER_NAME`, `CONTAINER_SIZE`
- Services logs use plural keys: `SERVICE_NAMES`, `IMAGE_NAMES`, `IMAGE_SIZES`, `CONTAINER_NAMES`, `CONTAINER_SIZES`
- Data mount flag (`DATA_MOUNT_USED`: `true` when a relevant bind mount is used, otherwise `false`)
- Dev logs also include component flags: `ENABLE_USER_CONFIG`, `ENABLE_JUPYTER_SETTINGS`, `ENABLE_GIT_IDENTITY`, `ENABLE_PYTHON_ENV`, `ENABLE_R_ENV`, `ENABLE_TEXLIVE`, `ENABLE_QUARTO`, and the summary field `ENABLED_COMPONENTS`

## Environment configuration

Non-secret configuration is split into:

- `devcontainer/env-vars/.env.build`
- `devcontainer/env-vars/.env.runtime`

Secret configuration is split into:

- `devcontainer/env-vars/.env.secrets.build`
- `devcontainer/env-vars/.env.secrets.runtime`

Common build variables:

- `DEVCONTAINER_OS_IMAGE`
- `DOTFILES_REPO`
- `ENABLE_GIT_IDENTITY`, `GIT_USER_NAME`, `GIT_USER_EMAIL`
- `ENABLE_USER_CONFIG`, `ENABLE_JUPYTER_SETTINGS`, `ENABLE_GIT_IDENTITY`, `ENABLE_PYTHON_ENV`, `ENABLE_R_ENV`, `ENABLE_TEXLIVE`, `ENABLE_QUARTO`
- `PYTHON_VERSION`
- `R_BASE_VERSION`
- `FLOWER_PYTHON_VERSION`
- `CONDA_LOCK_VERSION`
- `UID`, `GID`
- `RETRY_ATTEMPTS`, `RETRY_DELAY_SECONDS`

Optional heavyweight dev components are controlled in `devcontainer/env-vars/.env.build`:

- `ENABLE_USER_CONFIG=true|false`
- `ENABLE_JUPYTER_SETTINGS=true|false`
- `ENABLE_GIT_IDENTITY=true|false`
- `ENABLE_PYTHON_ENV=true|false`
- `ENABLE_R_ENV=true|false`
- `ENABLE_TEXLIVE=true|false`
- `ENABLE_QUARTO=true|false`

The enable flag governs the whole component lifecycle:

- latest build: install it
- `make lock-dev-env-container`: lock it
- lock rebuild: require its lockfile and install from it

If a component is disabled, all three stages skip it. If a component is enabled in lock mode and its lockfile is missing, the build fails.

Capability notes:

- `ENABLE_USER_CONFIG=false` skips dotfiles, shell/tmux tooling setup, and Neovim config activation.
- `ENABLE_JUPYTER_SETTINGS=false` skips restoring the committed JupyterLab user settings during image build.
- `ENABLE_GIT_IDENTITY=false` skips build-time `git config --global` identity setup.
- `ENABLE_TEXLIVE=false` disables TinyTeX and extra LaTeX packages, so PDF rendering is unavailable.
- `ENABLE_PYTHON_ENV=false` disables the Python micromamba environment, so Jupyter/Python-backed workflows are unavailable.
- `ENABLE_R_ENV=false` disables the R micromamba environment, so R-backed workflows are unavailable.
- `ENABLE_QUARTO=false` skips Quarto installation entirely.
- When `ENABLE_PYTHON_ENV=true` or `ENABLE_R_ENV=true`, micromamba shell initialization is added to `~/.zshrc` so `micromamba activate <env>` works in interactive shells; no environment is auto-activated by default.

Common runtime variables:

- `TZ`
- `ENABLE_HOST_GIT_ACCESS`
- `HOST_DATA_READ_ONLY`
- `HOST_DATA_MOUNT_PATH`
- `HOST_DATA_SYMLINK_PATH`
- `JUPYTER_PORT`
- `QUARTO_PORT`
- `WEB_APP_PORT`
- `POSTGRES_*`, `MYSQL_*`, `REDIS_*`, `NGINX_*`, `CELERY_*`, `FLOWER_*`

The secret files are committed as templates (keys only, empty values). Set values locally on each machine.
For `HOST_DATA_DIR`, use an absolute path without spaces and without quotation marks.
For `HOST_SSH_AUTH_SOCK_PATH`, `HOST_SSH_CONFIG_PATH`, and `HOST_SSH_KNOWN_HOSTS_PATH`, also use absolute file paths without quotes.
For service data paths (`*_DATA_DIR`), also use absolute paths without quotes.

Primary user-editable configuration files:

- `devcontainer/env-vars/.env.build` - build-time inputs such as base image, feature flags, runtime versions, retry settings, and dev image name.
- `devcontainer/env-vars/.env.runtime` - runtime inputs such as ports, timezone, host mount behavior, and dev container name.
- `devcontainer/env-vars/.env.secrets.build` - build-time secret values and local machine-specific build inputs.
- `devcontainer/env-vars/.env.secrets.runtime` - runtime secret values and local machine-specific runtime paths, credentials, and service data directories.
- `devcontainer/python-environment/python-environment.yml` - latest-mode Python environment definition for the dev container and Celery service images.
- `devcontainer/r-environment/r-environment.yml` - latest-mode R environment definition for the dev container.
- `devcontainer/services-environment/flower/flower-environment.yml` - latest-mode Python environment definition for the Flower service image.
- `devcontainer/latex-environment/latex-packages.txt` - selected TeX Live packages to install in latest mode.
- `devcontainer/build-assets/jupyterlab-user-settings.tar.gz` - archived JupyterLab user settings restored into the dev container when enabled.
- `devcontainer/additional-binaries-environment/additional-binaries.list` - enabled additional binaries and their install order; per-binary install metadata is defined in `devcontainer/additional-binaries-environment/additional-binaries/*.env`.
- `devcontainer/dotfiles-environment/dotfiles.list` - enabled dotfiles stow packages and their activation order.
- `devcontainer/base-binaries-environment/base-binaries.list` - enabled apt-installed base binaries.
- `devcontainer/.devcontainer/devcontainer.json` - VS Code Dev Containers metadata for attaching to the `dev` service, setting the remote user/workspace, and installing editor extensions.

## Environment variable loading model

Environment variables are now loaded by Docker Compose directly from:

- `devcontainer/env-vars/.env.build`
- `devcontainer/env-vars/.env.runtime`
- `devcontainer/env-vars/.env.secrets.build`
- `devcontainer/env-vars/.env.secrets.runtime`

The Makefile no longer acts as the primary env-variable source of truth.
It calls Docker Compose with explicit `--env-file` flags, so variable resolution is consistent across:

- `docker-compose.yml`
- `docker-compose.data.yml`
- `docker-compose.services.yml`
- `docker-compose.services-lock.yml`

Notes:

- Commented variables are not loaded.
- Unset variables resolve to empty values unless you enforce checks.
- Service validation checks in `make up-services-latest` / `make rebuild-services-latest` still fail early for required paths/passwords.
- Build-only values come from `devcontainer/env-vars/.env.build` and `devcontainer/env-vars/.env.secrets.build`, then flow through `build.args`.
- Runtime container variables come from `devcontainer/env-vars/.env.runtime` and `devcontainer/env-vars/.env.secrets.runtime` via `env_file`.
- Runtime tool-path variables inside the dev container are initialized in `devcontainer/shell-scripts/export-runtime-env.sh`, sourced by `devcontainer/shell-scripts/entrypoint.sh` and by interactive zsh shells through a managed `~/.zshrc` block.
- Lock scripts that need version values read them from `devcontainer/env-vars/.env.build`.

## Development vs production secrets

Development (this repo):

- Build secrets are stored in `devcontainer/env-vars/.env.secrets.build` on the local machine.
- Runtime secrets are stored in `devcontainer/env-vars/.env.secrets.runtime` on the local machine.
- Compose passes those values to containers as environment variables.
- This is acceptable for local development and smoke tests.

Production (recommended):

- Do not keep secrets in repo-managed env files.
- Use a secret manager or Docker/Kubernetes secrets.
- Inject only the secrets each service needs, with least-privilege scope.

## Host data mount

External host data is optional and controlled by `HOST_DATA_DIR` in `devcontainer/env-vars/.env.secrets.runtime`.

- `make up-dev-env-latest`, `make rebuild-dev-env-latest`, `make up-dev-env-lock`, and `make rebuild-dev-env-lock` automatically include the data-mount compose file when `HOST_DATA_DIR` is non-empty.
- If `HOST_DATA_DIR` is set, Docker Compose adds a bind mount:
  - host: `HOST_DATA_DIR`
  - container: `HOST_DATA_MOUNT_PATH`
  - mode: controlled by `HOST_DATA_READ_ONLY` in `devcontainer/env-vars/.env.runtime`
- On container startup, a symlink is created:
  - `HOST_DATA_SYMLINK_PATH -> HOST_DATA_MOUNT_PATH`
- If `HOST_DATA_DIR` is empty, data mount is skipped (no bind mount, no symlink).
- If `HOST_DATA_DIR` is set, Make validates it before build/start:
  - must be an absolute path
  - must exist on host as a directory
  - otherwise target fails fast

## Optional host Git/SSH access

Git access from inside the dev container is optional and controlled by `ENABLE_HOST_GIT_ACCESS` in `devcontainer/env-vars/.env.runtime`.

- If `ENABLE_HOST_GIT_ACCESS=false` (default), the dev container gets no host SSH integration.
- If `ENABLE_HOST_GIT_ACCESS=true`, dev targets enable SSH agent access inside the container.
- This lets Git/SSH inside the container use the SSH identities already loaded in the host `ssh-agent` without copying private keys into the container.
- If Docker Desktop is detected, the feature uses Docker Desktop's SSH agent bridge at `/run/host-services/ssh-auth.sock`.
- Otherwise, the feature uses `HOST_SSH_AUTH_SOCK_PATH` from `devcontainer/env-vars/.env.secrets.runtime`.
- If `ENABLE_HOST_GIT_ACCESS=true` and `HOST_SSH_AUTH_SOCK_PATH` is required but empty, not absolute, or not a socket, the dev target fails before Docker Compose runs.

Optional host SSH file mounts are configured in `devcontainer/env-vars/.env.secrets.runtime`:

- `HOST_SSH_AUTH_SOCK_PATH`: Required only when Docker Desktop is not detected. This is the host path to the SSH agent socket that should be mounted into the dev container.
- `HOST_SSH_CONFIG_PATH`: Optional read-only mount for host `~/.ssh/config`. Useful only if you rely on SSH aliases or host-specific SSH settings.
- `HOST_SSH_KNOWN_HOSTS_PATH`: Optional read-only mount for host `~/.ssh/known_hosts`. Useful only if you want to avoid first-connect host verification prompts inside the container.
- If either path is set, it must be an absolute path to an existing file.

Requirements on the host machine:

- `ssh` must be installed.
- `ssh-agent` must be running.
- At least one SSH key must be loaded into the agent.
- GitHub/GitLab SSH access should already work on the host before enabling the feature.

Useful host-side checks:

- `echo $SSH_AUTH_SOCK`
- `ssh-add -l`
- `ssh -T git@github.com`

Git commit identity:

- SSH authentication and Git commit identity are separate concerns.
- If `GIT_USER_NAME` and `GIT_USER_EMAIL` are both set in `devcontainer/env-vars/.env.build`, the image build configures:
  - `git config --global user.name`
  - `git config --global user.email`
- If both are empty, Git identity setup is skipped.
- If only one of the two is set, the image build fails fast because the configuration would be incomplete.

Docker Desktop setup (macOS, and Linux when using Docker Desktop):

- Docker Desktop provides an SSH agent bridge at `/run/host-services/ssh-auth.sock`.
- When Docker Desktop is detected, the devcontainer uses that socket automatically.
- No host symlink is needed in this mode.
- In this mode, `HOST_SSH_AUTH_SOCK_PATH` can stay empty.
- Docker Desktop exposes this socket as `root:root` with group write permissions, so the dev container adds `dev` to group `0` only in this mode when host Git access is enabled.

Non-Docker-Desktop setup:

- Set `HOST_SSH_AUTH_SOCK_PATH` to the real host SSH agent socket path.
- This is the mode intended for native Linux Docker engines.
- You can usually discover the correct host socket path with:
  - `echo $SSH_AUTH_SOCK`

Windows / WSL2:

- The repo treats WSL2 Docker Desktop setups as Docker Desktop mode.
- In that case it uses `/run/host-services/ssh-auth.sock`.
- There is no separate Windows-specific SSH agent mount path in the repo.

Typical setups:

- Single GitHub account on one machine: set `ENABLE_HOST_GIT_ACCESS=true`; no extra SSH file mounts are usually needed.
- Multiple Git accounts or GitHub/GitLab aliases on one machine: also set `HOST_SSH_CONFIG_PATH`.
- Pre-seeded trusted host keys inside container: also set `HOST_SSH_KNOWN_HOSTS_PATH`.

## Python and R version pins

Python and R runtime versions are controlled centrally via `.env`:

- `PYTHON_VERSION` renders `devcontainer/python-environment/python-environment.yml` at build/lock time.
- `R_BASE_VERSION` renders `devcontainer/r-environment/r-environment.yml` at build/lock time.
- `FLOWER_PYTHON_VERSION` renders `devcontainer/services-environment/flower/flower-environment.yml` at build/lock time.
- Keep `FLOWER_PYTHON_VERSION` aligned with `PYTHON_VERSION` unless you explicitly want different runtimes.

## python-environment

Mamba environment specs live in `devcontainer/python-environment/`:

- `python-environment.yml`: Source of truth for package selection.
- `python-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-python-env` or `make lock-dev-env-container` to create it).

Python is installed in a separate micromamba environment named `python-env`.

Note: `conda-lock` handling is driven by the lock scripts. Keep the lock tooling/version behavior in sync with `devcontainer/shell-scripts/lock-python-env.sh` if you change the workflow.

## R packages

R environment specs live in `devcontainer/r-environment/`:

- `r-environment.yml`: Source of truth for package selection.
- `r-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-r-env` or `make lock-dev-env-container` to create it).

R is installed in a separate micromamba environment named `r-env`.

## LaTeX packages

Additional LaTeX packages are managed via `devcontainer/latex-environment/latex-packages.txt` and installed during the image build by `devcontainer/shell-scripts/install-latex-packages.sh`. Uncomment the packages you need and rebuild the image.
TinyTeX itself is installed via `devcontainer/shell-scripts/install-tinytex.sh` using a temporary micromamba installer environment (`tinytex-installer`), so `r-env` remains focused on analysis packages.
`make lock-latex-env` now resolves latest TeX Live upstream (`mirror.ctan.org`), stores the effective mirror URL, and records `tlpdb_sha256` to capture upstream state at lock time.

## Quarto

Quarto is installed user-local from GitHub release tarballs (not from conda):

- Non-lock builds install the latest stable release (`releases/latest`).
- Lock builds install the exact version and architecture URL stored in `devcontainer/quarto-environment/quarto-lock.env`.
- Lock generation resolves latest GitHub release assets (`amd64` and `arm64`) so lock captures upstream state at lock time.
- Lockfile also stores SHA256 for both assets, and lock installs verify checksums before extraction.

## Micromamba

Micromamba is installed from GitHub releases (`mamba-org/micromamba-releases`):

- Non-lock builds resolve the latest release via GitHub API and install the matching Linux asset for the current architecture.
- Lock builds install exact URLs from `devcontainer/micromamba-environment/micromamba-lock.env`.
- Lock generation (`make lock-micromamba-env` or `make lock-dev-env-container`) resolves latest GitHub release assets for both Linux architectures (`amd64`, `arm64`) and writes them to the lockfile.
- Lockfile also stores SHA256 for both assets, and lock installs verify checksums before extraction.

## OS base image lock

Host-side OS and base-binaries locking are handled separately from in-container lock targets:

- `make lock-os-image-host` (host) reads `DEVCONTAINER_OS_IMAGE` from `devcontainer/env-vars/.env.build`.
- If it is a moving tag (for example `debian:13-slim`), it resolves linux platform child digests from the multi-arch manifest list and writes:
  - `devcontainer/os-environment/os-lock.env`
- `make lock-base-binaries-host` (host) reads `devcontainer/os-environment/os-lock.env`, inspects the locked host-arch image, and writes:
  - `devcontainer/base-binaries-environment/base-binaries-lock.env`
- OS lockfile keys:
  - `DEVCONTAINER_OS_IMAGE_AMD64`
  - `DEVCONTAINER_OS_IMAGE_ARM64`
- Base-binaries lockfile keys:
  - `APT_SNAPSHOT_TIMESTAMP`
  - `APT_DIST_ID`
  - `APT_DIST_CODENAME`
  - `APT_MAIN_BASE_URL`, `APT_SECURITY_BASE_URL`
  - `APT_MAIN_RELEASE_SHA256`, `APT_UPDATES_RELEASE_SHA256`, `APT_SECURITY_RELEASE_SHA256`
- Lock-mode builds pin apt to distro-aware snapshot sources (Debian/Ubuntu) and verify these `Release` file hashes after `apt-get update`.
- `make up-dev-env-latest-os-lock` / `make rebuild-dev-env-latest-os-lock` use both host lockfiles while keeping package-resolution mode at `DEV_ENV_LOCKED=0`.
- Lock-mode dev builds (`up/rebuild-*-lock`) also require both host lockfiles and use them automatically.

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
- `devcontainer/env-vars/.env.build`: set build-time non-secret variables (image, versions, dotfiles repo, git identity, retry settings).
- `devcontainer/env-vars/.env.runtime`: set runtime non-secret variables (timezone, ports, optional host Git/data settings, service image tags/commands).
- `devcontainer/env-vars/.env.secrets.build`: set build-time secrets (`DEV_USER_PASSWORD`).
- `devcontainer/env-vars/.env.secrets.runtime`: set runtime secrets and absolute host paths (`*_PASSWORD`, `*_DATA_DIR`, config/code paths).

After enabling a service:

- run `make lock-services` to refresh digest locks for active pull-based services.
- run `make rebuild-services-latest` (latest mode) or `make rebuild-services-lock` (lock mode).

Current default:

- All additional services are commented out by default in `devcontainer/docker/docker-compose.services.yml`.
- Enable only the services required for your current project.

Adding a new service:

- Add the service definition to `devcontainer/docker/docker-compose.services.yml`. This is the primary file that joins the service to the same Compose project and network as the dev container and all other services.
- If the service is pull-based, add the matching lock override to `devcontainer/docker/docker-compose.services-lock.yml` so lock mode can replace tags with digests.
- If the service is build-based, add its Dockerfile and any service-specific environment files under `devcontainer/services-environment/<service>/`, then wire its build args in `devcontainer/docker/docker-compose.services.yml`.
- Add required variables to the correct env files:
  - `devcontainer/env-vars/.env.build` for build-time non-secret values
  - `devcontainer/env-vars/.env.runtime` for runtime non-secret values such as ports, image tags, commands
  - `devcontainer/env-vars/.env.secrets.build` for build-time secrets
  - `devcontainer/env-vars/.env.secrets.runtime` for runtime secrets, host paths, and bind-mount sources
- If the service is pull-based and should participate in lock mode, extend `devcontainer/shell-scripts/lock-services-env.sh` so `make lock-services` resolves and validates its digest variables.
- If the service needs repo-managed config files, store them under `devcontainer/services-environment/<service>/` and bind-mount them from `devcontainer/docker/docker-compose.services.yml`.
- If the service needs persistent host data, add the required `*_DATA_DIR` runtime secret variable and bind mount in `devcontainer/docker/docker-compose.services.yml`.

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
- `make up-services-latest` / `make rebuild-services-latest` build Celery with `DEV_ENV_LOCKED=0`.
- `make up-services-lock` / `make rebuild-services-lock` build Celery with `DEV_ENV_LOCKED=1`.

Locking behavior:

- Non-lock service commands use the image tags from `devcontainer/env-vars/.env.runtime` (e.g. `postgres:latest`).
- `make lock-services` resolves and stores linux platform child digests in `devcontainer/services-environment/services-lock.env` for both architectures (for example `POSTGRES_IMAGE_LOCK_AMD64` and `POSTGRES_IMAGE_LOCK_ARM64`).
- Lock service commands use those stored digests.
- Service commands automatically target all uncommented services in `devcontainer/docker/docker-compose.services.yml` (excluding the `dev` container).
- Build-based services (`celery-worker`, `celery-beat`, `flower`) are not digest-locked by `make lock-services`.
- `make lock-services` still updates `devcontainer/services-environment/flower/flower-environment-lock.yml` by invoking `make lock-flower-env` inside the running dev container.
- Because of that Flower step, `make lock-services` requires the dev container to be running first.
- Keep `devcontainer/docker/docker-compose.services-lock.yml` aligned with `devcontainer/docker/docker-compose.services.yml` for pull-based services:
  - If a service is commented in `docker-compose.services.yml`, keep it commented in `docker-compose.services-lock.yml`.
  - If a lock entry is enabled but its `*_IMAGE_LOCK_AMD64` / `*_IMAGE_LOCK_ARM64` keys are absent in `services-lock.env`, lock rebuilds fail.

Minimal enable workflow:

1. Uncomment the service in `devcontainer/docker/docker-compose.services.yml`.
2. For pull-based services, uncomment the matching lock override in `devcontainer/docker/docker-compose.services-lock.yml`.
3. Set required build/runtime vars in `devcontainer/env-vars/.env.build` and `devcontainer/env-vars/.env.runtime`, plus any needed secrets/paths in `devcontainer/env-vars/.env.secrets.build` and `devcontainer/env-vars/.env.secrets.runtime`.
4. Run `make lock-services` to refresh `devcontainer/services-environment/services-lock.env`.
5. Run `make rebuild-services-latest` (latest mode) or `make rebuild-services-lock` (lock mode).

Lock verification:

- Render latest images:
  - `docker compose --env-file env-vars/.env.build --env-file env-vars/.env.runtime --env-file env-vars/.env.secrets.build --env-file env-vars/.env.secrets.runtime -f docker/docker-compose.yml -f docker/docker-compose.services.yml config | rg 'image:'`
- Render lock images:
  - `eval "$(sh shell-scripts/export-cross-platform-lock-vars.sh all)" && DEV_ENV_LOCKED=1 docker compose --env-file env-vars/.env.build --env-file env-vars/.env.runtime --env-file env-vars/.env.secrets.build --env-file env-vars/.env.secrets.runtime --env-file os-environment/os-lock.env --env-file services-environment/services-lock.env -f docker/docker-compose.yml -f docker/docker-compose.services.yml -f docker/docker-compose.services-lock.yml config | rg 'image:'`
- Verify running pull-based services use digest refs:
  - `docker inspect dev_postgres --format '{{.Config.Image}}'`
  - `docker inspect dev_redis --format '{{.Config.Image}}'`
  - `docker inspect dev_nginx --format '{{.Config.Image}}'`

Recommended config mount location:

- `devcontainer/services-environment/nginx/` stores Nginx service config files.
- Use absolute host paths in `devcontainer/env-vars/.env.secrets.runtime` for `*_CONFIG_DIR`.

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

- `make up-dev-env-latest` / `make rebuild-dev-env-latest` installs the latest Python/R/LaTeX packages (selected by `DEV_ENV_LOCKED=0`).
- `make up-dev-env-latest-os-lock` / `make rebuild-dev-env-latest-os-lock` uses latest package resolution (`DEV_ENV_LOCKED=0`) while pinning both the OS base image and apt/base-binaries snapshot via the host lockfiles.
- `make up-dev-env-lock` / `make rebuild-dev-env-lock` installs from lockfiles (`DEV_ENV_LOCKED=1`).
- `make lock-dev-env-container` generates/updates lockfiles for micromamba (GitHub release assets), additional binaries (GitHub release assets), user tooling repos (git commit refs), dotfiles repo (git commit ref), Python (conda-lock), R (conda-lock), LaTeX (TeX Live repository), and Quarto (GitHub release URLs).
- `make lock-additional-binaries-env` generates/updates `devcontainer/additional-binaries-environment/additional-binaries-lock.env` for additional binaries (`fzf`, `neovim`, `lsd`) with amd64/arm64 URLs and SHA256 checksums.
  - Enabled binaries and order come from `devcontainer/additional-binaries-environment/additional-binaries.list`.
  - Binary metadata is read from one file per binary in `devcontainer/additional-binaries-environment/additional-binaries/` (no hardcoded defaults in install script).
- `make lock-tooling-config-env` generates/updates `devcontainer/tooling-config-environment/tooling-config-lock.env` with pinned git commit refs for oh-my-zsh and tmux/zsh plugin repos.
- `make lock-dotfiles-env` generates/updates `devcontainer/dotfiles-environment/dotfiles-lock.env` with pinned `DOTFILES_REPO` and `DOTFILES_REF`.
- `make lock-os-image-host` generates/updates `devcontainer/os-environment/os-lock.env` for deterministic base-image resolution.
- `make lock-base-binaries-host` generates/updates `devcontainer/base-binaries-environment/base-binaries-lock.env` for apt/base-binaries snapshot locking.
- `make lock-dev-env-host` runs both host-side lock steps together.
- Lock-mode targets auto-select the right digest for host architecture (`amd64` or `arm64`) via `devcontainer/shell-scripts/export-cross-platform-lock-vars.sh`.
- OS/service lock generation requires multi-arch images with `linux/amd64` and `linux/arm64` entries; otherwise locking fails fast.
- All `lock-*` targets capture current upstream/latest state at lock time, then `*-lock` builds use those pinned lockfiles for deterministic rebuilds.

Fallback behavior:

- In lock mode, missing lockfiles now fail fast:
  - Base OS image: `os-environment/os-lock.env`
  - Base binaries / apt snapshot: `base-binaries-environment/base-binaries-lock.env`
  - Additional binaries: `additional-binaries-environment/additional-binaries-lock.env`
  - Additional tooling repos: `tooling-config-environment/tooling-config-lock.env`
  - Dotfiles repo: `dotfiles-environment/dotfiles-lock.env`
  - Micromamba: `micromamba-environment/micromamba-lock.env`
  - Python: `python-environment/python-environment-lock.yml`
  - Celery worker/beat (service image build): `python-environment/python-environment-lock.yml`
  - R: `r-environment/r-environment-lock.yml`
  - LaTeX: `latex-environment/latex-environment-lock.txt`
  - Quarto: `quarto-environment/quarto-lock.env`
  - Flower: `services-environment/flower/flower-environment-lock.yml`
- Non-lock mode continues to install from the latest environment/package definitions.
- Python uses `python-environment/python-environment.yml` for latest and `python-environment/python-environment-lock.yml` for locked installs.
- R uses `r-environment/r-environment.yml` for latest and `r-environment/r-environment-lock.yml` for locked installs.
- LaTeX uses `latex-environment/latex-packages.txt` for latest and `latex-environment/latex-environment-lock.txt` for locked installs.
- Quarto uses GitHub latest for latest and `quarto-environment/quarto-lock.env` for lock; lock mode is strict (no fallback).
- Micromamba uses GitHub release latest for latest and `micromamba-environment/micromamba-lock.env` for lock; lock mode is strict (no fallback).
- Additional binaries (`fzf`, `neovim`, `lsd`) use GitHub latest in latest and `additional-binaries-environment/additional-binaries-lock.env` in lock mode; lock mode verifies SHA256 and is strict (no fallback).
- Enabled additional binaries and their install order are defined in `additional-binaries-environment/additional-binaries.list`; empty lines and lines starting with `#` are ignored, so binaries can be disabled by commenting them out.
- Additional tooling (oh-my-zsh, zsh plugins/theme, tmux TPM) uses latest git HEAD in latest and `tooling-config-environment/tooling-config-lock.env` in lock mode; lock mode is strict (missing lockfile/refs fails).
- Dotfiles (`zsh`, `tmux`, `nvim` stow source) uses latest default branch HEAD in latest and `dotfiles-environment/dotfiles-lock.env` in lock mode; lock mode is strict (missing lockfile/refs fails).
- Enabled dotfiles stow packages and their install order are defined in `dotfiles-environment/dotfiles.list`; empty lines and lines starting with `#` are ignored, so packages can be disabled by commenting them out.
- Base binaries are defined in `base-binaries-environment/base-binaries.list`.
- Empty lines and lines starting with `#` are ignored, so binaries can be disabled by commenting them out.
- Apt repositories use live distro mirrors in latest mode and distro-aware snapshot sources (Debian/Ubuntu) with `APT_SNAPSHOT_TIMESTAMP` from `base-binaries-environment/base-binaries-lock.env` in lock mode.

Locking guidance:

- For reproducibility, run `make lock-dev-env-and-rebuild` from host for a full deterministic refresh.
- After locking, prefer `make up-dev-env-lock` / `make rebuild-dev-env-lock` for consistent rebuilds.
- Run `make lock-dev-env-container` and language-specific `make lock-<env>` targets inside the dev container. When `ENABLE_USER_CONFIG=false`, tooling-config and dotfiles lock generation is skipped.
- Run `make lock-dev-env-host` from the host in the `devcontainer/` directory for host-side locks only.
- Run `make lock-services` from the host in the `devcontainer/` directory.
- Recommended host pipeline: `make lock-dev-env` (lock only) or `make lock-dev-env-and-rebuild` (lock + rebuild from lockfiles).
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
- `make lock-micromamba-env` updates `devcontainer/micromamba-environment/micromamba-lock.env`
- `make lock-additional-binaries-env` updates `devcontainer/additional-binaries-environment/additional-binaries-lock.env`
- `make lock-tooling-config-env` updates `devcontainer/tooling-config-environment/tooling-config-lock.env`
- `make lock-dotfiles-env` updates `devcontainer/dotfiles-environment/dotfiles-lock.env`
- `make lock-os-image-host` updates `devcontainer/os-environment/os-lock.env`
- `make lock-base-binaries-host` updates `devcontainer/base-binaries-environment/base-binaries-lock.env`

Locked installs are handled by:

- Python: `devcontainer/shell-scripts/install-python-packages.sh` (`DEV_ENV_LOCKED` branch)
- R: `devcontainer/shell-scripts/install-r-packages.sh` (`DEV_ENV_LOCKED` branch)
- LaTeX: `devcontainer/shell-scripts/install-latex-packages.sh` (`DEV_ENV_LOCKED` branch)
- Quarto: `devcontainer/shell-scripts/install-quarto.sh` (`DEV_ENV_LOCKED` branch)
- Flower: `devcontainer/shell-scripts/install-flower-packages.sh` (`DEV_ENV_LOCKED` branch)
- Micromamba: `devcontainer/shell-scripts/install-micromamba.sh` (`DEV_ENV_LOCKED` branch)
- Additional binaries: `devcontainer/shell-scripts/install-additional-binaries.sh` (`DEV_ENV_LOCKED` branch)
- Additional tooling (oh-my-zsh/tmux plugins): `devcontainer/shell-scripts/install-tooling-config.sh` (`DEV_ENV_LOCKED` branch)
- Dotfiles (stow source repo): `devcontainer/shell-scripts/install-dotfiles.sh` (`DEV_ENV_LOCKED` branch)
- Neovim config activation (Lazy sync): `devcontainer/shell-scripts/activate-nvim-config.sh`

Clean lock targets:

- `make clean-lock-all`
- `make clean-lock-python`
- `make clean-lock-r`
- `make clean-lock-latex`
- `make clean-lock-quarto`
- `make clean-lock-flower`
- `make clean-lock-micromamba`
- `make clean-lock-additional-binaries`
- `make clean-lock-tooling-config`
- `make clean-lock-dotfiles`
- `make clean-lock-os-image`
- `make clean-lock-base-binaries`
- `make clean-lock-services`

All `clean-lock-*` targets can run on host or inside the container.
`make clean-lock-os-image` removes only `os-environment/os-lock.env`.
`make clean-lock-base-binaries` removes only `base-binaries-environment/base-binaries-lock.env`.

## Template repo setup

When creating a new repo from this template, edit the env files you need:

- `devcontainer/env-vars/.env.build`
- `devcontainer/env-vars/.env.runtime`
- `devcontainer/env-vars/.env.secrets.build`
- `devcontainer/env-vars/.env.secrets.runtime`

and set local values for the keys you need (for example `HOST_DATA_DIR`).

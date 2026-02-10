# Readme

## Create new repo from template

```bash
  gh repo create <your-org-or-user>/<new-repo-name> \
    --template <your-org-or-user>/<devcontainer-template-repo> \
    --description "My new project based on the devcontainer template" \
    --gitignore Python \
    --public \
    --clone
```

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

## .env.secrets

Secret configuration values live in `devcontainer/env-vars/.env.secrets`.
This file is committed as a template (keys only, empty values).
Set values locally on each machine.
For `HOST_DATA_DIR`, use an absolute path without spaces and without quotation marks.

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

## python-environment

Mamba environment specs live in `devcontainer/python-environment/`:

- `python-environment.yml`: Source of truth for package selection.
- `python-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-mamba-env` or `make lock-dev-env` to create it).

Python is installed in a separate micromamba environment named `python-env`.

Note: `conda-lock` handling is driven by the lock scripts. Keep the lock tooling/version behavior in sync with `devcontainer/shell-scripts/lock-mamba-env.sh` if you change the workflow.

## JupyterLab settings

If you want to persist your custom settings, export them with `make jupyter-settings-export` (inside the container). The archive is stored in `devcontainer/build-assets/jupyterlab-user-settings.tar.gz` and restored at build time by `devcontainer/shell-scripts/restore-jupyterlab-settings.sh`.

## LaTeX packages

Additional LaTeX packages are managed via `devcontainer/latex-environment/latex-packages.txt` and installed during the image build by `devcontainer/shell-scripts/install-latex-packages.sh`. Uncomment the packages you need and rebuild the image.
TinyTeX itself is installed via `devcontainer/shell-scripts/install-tinytex.sh` using a temporary micromamba installer environment (`tinytex-installer`), so `r-env` remains focused on analysis packages.

## R packages

R environment specs live in `devcontainer/r-environment/`:

- `r-environment.yml`: Source of truth for package selection.
- `r-environment-lock.yml`: Generated lockfile for reproducible builds (run `make lock-r-env` or `make lock-dev-env` to create it).

R is installed in a separate micromamba environment named `r-env`.

## Quarto

Quarto is installed user-local from GitHub release tarballs (not from conda):

- Non-lock builds install the latest stable release (`releases/latest`).
- Lock builds install the exact version and architecture URL stored in `devcontainer/quarto-environment/quarto-lock.env`.
- Lock generation validates both Linux assets (`amd64` and `arm64`) so the same lockfile works across chips.

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

Individual lock targets:

- `make lock-mamba-env` updates `devcontainer/python-environment/python-environment-lock.yml`
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
- `make clean-lock-mamba`
- `make clean-lock-r`
- `make clean-lock-latex`
- `make clean-lock-quarto`

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
- `make shell`: Open a shell in the container.
- `make tmux`: Open tmux in the container.
- `make vscode`: Open VS Code for this repo (then "Reopen in Container").
- `make jupyter`: Start JupyterLab inside the container.
- Quarto live preview: `quarto preview <file>.qmd --host 0.0.0.0 --port ${QUARTO_PORT:-4200}`.
- `make lock-dev-env`: Generate lockfiles for Python, R, LaTeX, and Quarto (run inside the container).
- `make jupyter-settings-export`: Export JupyterLab user settings to `devcontainer/build-assets/` (run inside the container).
- `make jupyter-settings-restore`: Restore JupyterLab user settings from `devcontainer/build-assets/` (run inside the container).

## Template repo setup

When creating a new repo from this template, edit `devcontainer/env-vars/.env.secrets`
and set local values for the keys you need (for example `HOST_DATA_DIR`).

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

Non-secret configuration values live in `devcontainer/.env`.

Common variables:

- `JUPYTER_PORT`: Port to expose JupyterLab (default: `8888`).
- `TZ`: Container timezone (default: `UTC`).
- `UID`: Host user id for file ownership (default: `1000`).
- `GID`: Host group id for file ownership (default: `1000`).

## .env.secrets

Secret configuration values live in `devcontainer/.env.secrets`.
Keep this file out of version control.

## mamba_environment

Mamba environment specs live in `devcontainer/mamba_environment/`:

- `environment.yml`: Source of truth for package selection.
- `conda-lock.yml`: Generated lockfile for reproducible builds (run `make lock-mamba-env` or `make lock-dev-env` to create it).

Python is installed in a separate micromamba environment named `python-env`.

Note: `conda-lock` is pinned in `environment.yml`. Changing its version can break the lockfile generation/install CLI, so avoid upgrading it unless you also adjust the build workflow.

## JupyterLab settings

If you want to persist your custom settings, export them with `make jupyter-settings-export` (inside the container). The archive is stored in `devcontainer/build_assets/jupyterlab-user-settings.tar.gz` and restored at build time by `devcontainer/shell_scripts/restore-jupyterlab-settings.sh`.

## LaTeX packages

Additional LaTeX packages are managed via `devcontainer/latex-environment/latex-packages.txt` and installed during the image build by `devcontainer/shell_scripts/install-latex-packages.sh`. Uncomment the packages you need and rebuild the image.

## R packages

Additional R packages are managed via `devcontainer/r-environment/r-packages.txt` and installed from CRAN during the image build by `devcontainer/shell_scripts/install-r-packages.sh`. Uncomment the packages you need and rebuild the image. R locking is handled via pak (`devcontainer/r-environment/pak.lock`).

## Locked vs latest builds

Use the unified targets for reproducible builds:

- `make up-dev-env` / `make rebuild-dev-env` installs the latest Python/R/LaTeX packages (selected by `DEV_ENV_LOCKED=0`).
- `make up-dev-env-lock` / `make rebuild-dev-env-lock` installs locked packages if lockfiles exist and falls back to latest when they do not (`DEV_ENV_LOCKED=1`).
- `make lock-dev-env` generates/updates lockfiles for Python (conda-lock), R (pak), and LaTeX (TeX Live snapshot URL).

Fallback behavior:

- If a lockfile is missing or invalid, the build falls back to the latest package list for that language.
- If both a lockfile and the latest package list are missing, the installer skips that language instead of failing.
- Python uses `mamba_environment/environment.yml` for latest and `mamba_environment/conda-lock.yml` for locked installs.
- R uses `r-environment/r-packages.txt` for latest and `r-environment/pak.lock` for locked installs.
- LaTeX uses `latex-environment/latex-packages.txt` for latest and `latex-environment/texlive-repo.txt` for locked installs.

Locking guidance:

- For reproducibility, run `make lock-dev-env` immediately after installing/updating packages.
- After locking, prefer `make up-dev-env-lock` / `make rebuild-dev-env-lock` for consistent rebuilds.

Individual lock targets:

- `make lock-mamba-env` updates `devcontainer/mamba_environment/conda-lock.yml`
- `make lock-r-env` updates `devcontainer/r-environment/pak.lock`
- `make lock-latex-env` updates `devcontainer/latex-environment/texlive-repo.txt`

Locked installs are handled by:

- Python: `devcontainer/shell_scripts/install-python-packages-lock.sh`
- R: `devcontainer/shell_scripts/install-r-packages-lock.sh`
- LaTeX: `devcontainer/shell_scripts/install-latex-packages-lock.sh`

Clean lock targets (run inside container):

- `make clean-locks`
- `make clean-lock-mamba`
- `make clean-lock-r`
- `make clean-lock-latex`

## Make commands

Run these from the `devcontainer` directory:

- `make up-dev-env`: Build and start using latest package definitions.
- `make rebuild-dev-env`: Rebuild using latest package definitions.
- `make up-dev-env-lock`: Build and start using lockfiles when present.
- `make rebuild-dev-env-lock`: Rebuild using lockfiles when present.
- `make shell`: Open a shell in the container.
- `make tmux`: Open tmux in the container.
- `make vscode`: Open VS Code for this repo (then "Reopen in Container").
- `make jupyter`: Start JupyterLab inside the container.
- `make lock-dev-env`: Generate lockfiles for Python, R, and LaTeX (run inside the container).
- `make jupyter-settings-export`: Export JupyterLab user settings to `devcontainer/build_assets/` (run inside the container).
- `make jupyter-settings-restore`: Restore JupyterLab user settings from `devcontainer/build_assets/` (run inside the container).

## Template repo setup

When creating a new repo from this template, add `devcontainer/.env.secrets` with your secret values and update your new repo's `.gitignore` to include:

```text
devcontainer/.env.secrets
```

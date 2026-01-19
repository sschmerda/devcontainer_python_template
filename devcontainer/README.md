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
- `conda-lock.yml`: Generated lockfile for reproducible builds (run `make env-lock` to create it).

Note: `conda-lock` is pinned in `environment.yml`. Changing its version can break the lockfile generation/install CLI, so avoid upgrading it unless you also adjust the build workflow.

## Make commands

Run these from the `devcontainer` directory:

- `make up`: Build and start the container.
- `make rebuild`: Rebuild from scratch and start.
- `make up-env`: Build and start using `mamba_environment/environment.yml`.
- `make rebuild-env`: Rebuild using `mamba_environment/environment.yml`.
- `make up-lock`: Build and start using `mamba_environment/conda-lock.yml`.
- `make rebuild-lock`: Rebuild using `mamba_environment/conda-lock.yml`.
- `make shell`: Open a shell in the container.
- `make tmux`: Open tmux in the container.
- `make vscode`: Open VS Code for this repo (then "Reopen in Container").
- `make jupyter`: Start JupyterLab inside the container.
- `make env-lock`: Generate `mamba_environment/conda-lock.yml` (run inside the container).

## Template repo setup

When creating a new repo from this template, add `devcontainer/.env.secrets` with your secret values and update your new repo's `.gitignore` to include:

```text
devcontainer/.env.secrets
```

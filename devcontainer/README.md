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

## Environment files

- `devcontainer/.env`: Non-secret configuration values.
- `devcontainer/.env.secrets`: Secret values. Keep this file out of version control.

## Template repo setup

When creating a new repo from this template, add `devcontainer/.env.secrets` with your secret values and update your new repo's `.gitignore` to include:

```text
devcontainer/.env.secrets
```

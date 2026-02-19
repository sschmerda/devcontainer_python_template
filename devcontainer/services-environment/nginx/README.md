# Nginx Service Config

This directory contains Nginx configuration files mounted into the nginx
service container at:

- `/etc/nginx/conf.d`

Set this directory as the host config source in:

- `devcontainer/env-vars/.env.secrets`
- `NGINX_CONF_DIR=/absolute/path/to/repo/devcontainer/services-environment/nginx`

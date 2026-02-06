#!/usr/bin/env sh
set -e

PORT="${JUPYTER_PORT:-8888}"
TOKEN="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"

URL="http://127.0.0.1:${PORT}/lab?token=${TOKEN}"
LINE="Jupyter Lab URL: ${URL}"
DASH_COUNT="$(printf '%s' "$LINE" | awk '{print length}')"
DASHES="$(printf '%*s' "$DASH_COUNT" '' | tr ' ' '-')"

printf '\n%s\n\033[32m%s\033[0m\n%s\n\n' "$DASHES" "$LINE" "$DASHES"
exec micromamba run -n python-env jupyter-lab --ip=0.0.0.0 --port="${PORT}" --no-browser --IdentityProvider.token="${TOKEN}"

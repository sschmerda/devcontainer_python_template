# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0
ARG BASE_BINARIES_LOCKED=0
ARG PYTHON_VERSION
ARG RETRY_ATTEMPTS
ARG RETRY_DELAY_SECONDS

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}
ENV BASE_BINARIES_LOCKED=${BASE_BINARIES_LOCKED}

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/shell-scripts/install-celery-packages.sh /tmp/install-celery-packages.sh
COPY devcontainer/shell-scripts/apply-apt-snapshot-state.sh /tmp/apply-apt-snapshot-state.sh
COPY devcontainer/shell-scripts/verify-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh
COPY devcontainer/micromamba-environment/ /tmp/micromamba-environment/
COPY devcontainer/os-environment/ /tmp/os-environment/
COPY devcontainer/base-binaries-environment/ /tmp/base-binaries-environment/
COPY devcontainer/python-environment/ /tmp/python-environment/

RUN chmod +x /tmp/apply-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh && /tmp/apply-apt-snapshot-state.sh

RUN apt-get update && /tmp/verify-apt-snapshot-state.sh && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh /tmp/install-celery-packages.sh && /tmp/install-micromamba.sh

RUN RETRY_ATTEMPTS="${RETRY_ATTEMPTS}" RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS}" /tmp/install-celery-packages.sh

WORKDIR /app/workspace

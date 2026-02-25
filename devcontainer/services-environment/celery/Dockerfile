# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/shell-scripts/install-celery-packages.sh /tmp/install-celery-packages.sh
COPY devcontainer/micromamba-environment/ /tmp/micromamba-environment/
COPY devcontainer/python-environment/ /tmp/python-environment/

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh /tmp/install-celery-packages.sh && /tmp/install-micromamba.sh

RUN /tmp/install-celery-packages.sh

WORKDIR /app/workspace

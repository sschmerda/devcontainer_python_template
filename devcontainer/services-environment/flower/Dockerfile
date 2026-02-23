# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/shell-scripts/install-flower-packages.sh /tmp/install-flower-packages.sh
COPY devcontainer/shell-scripts/install-flower-packages-lock.sh /tmp/install-flower-packages-lock.sh
COPY devcontainer/services-environment/flower/ /tmp/flower-environment/

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh /tmp/install-flower-packages.sh /tmp/install-flower-packages-lock.sh && /tmp/install-micromamba.sh

RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
      /tmp/install-flower-packages-lock.sh; \
    else \
      /tmp/install-flower-packages.sh; \
    fi

WORKDIR /app/workspace

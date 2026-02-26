# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/shell-scripts/install-flower-packages.sh /tmp/install-flower-packages.sh
COPY devcontainer/shell-scripts/apply-apt-snapshot-state.sh /tmp/apply-apt-snapshot-state.sh
COPY devcontainer/shell-scripts/verify-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh
COPY devcontainer/micromamba-environment/ /tmp/micromamba-environment/
COPY devcontainer/os-environment/ /tmp/os-environment/
COPY devcontainer/services-environment/flower/ /tmp/flower-environment/

RUN chmod +x /tmp/apply-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh && /tmp/apply-apt-snapshot-state.sh

RUN apt-get update && /tmp/verify-apt-snapshot-state.sh && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh /tmp/install-flower-packages.sh && /tmp/install-micromamba.sh

RUN /tmp/install-flower-packages.sh

WORKDIR /app/workspace

# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/python-environment/ /tmp/python-environment/

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh && /tmp/install-micromamba.sh

RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
      if [ ! -s /tmp/python-environment/python-environment-lock.yml ]; then \
        echo "Missing Python lockfile: /tmp/python-environment/python-environment-lock.yml"; \
        exit 1; \
      fi; \
      micromamba env create -y -n python-env -f /tmp/python-environment/python-environment-lock.yml; \
    else \
      if [ ! -s /tmp/python-environment/python-environment.yml ]; then \
        echo "Missing Python environment file: /tmp/python-environment/python-environment.yml"; \
        exit 1; \
      fi; \
      micromamba env create -y -n python-env -f /tmp/python-environment/python-environment.yml; \
    fi && \
    micromamba clean --all --yes --force-pkgs-dirs

WORKDIR /app/workspace

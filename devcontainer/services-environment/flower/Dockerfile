# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

ARG DEV_ENV_LOCKED=0

ENV HOME=/root
ENV PATH=/root/.local/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/root/.local/share/mamba

COPY devcontainer/shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY devcontainer/services-environment/flower/ /tmp/flower-environment/

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /tmp/install-micromamba.sh && /tmp/install-micromamba.sh

RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
      if [ ! -s /tmp/flower-environment/flower-environment-lock.yml ]; then \
        echo "Missing Flower lockfile: /tmp/flower-environment/flower-environment-lock.yml"; \
        exit 1; \
      fi; \
      micromamba create -y -n locktools -c conda-forge conda-lock=4.0.0; \
      micromamba run -n locktools conda-lock install --prefix "$MAMBA_ROOT_PREFIX/envs/celery-env" --micromamba /tmp/flower-environment/flower-environment-lock.yml; \
      micromamba env remove -n locktools -y; \
    else \
      if [ ! -s /tmp/flower-environment/flower-environment.yml ]; then \
        echo "Missing Flower environment file: /tmp/flower-environment/flower-environment.yml"; \
        exit 1; \
      fi; \
      micromamba env create -y -n celery-env -f /tmp/flower-environment/flower-environment.yml; \
    fi && \
    micromamba clean --all --yes --force-pkgs-dirs

WORKDIR /app/workspace

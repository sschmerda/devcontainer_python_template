# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

USER root
ARG DEV_ENV_LOCKED=0
ARG BASE_BINARIES_LOCKED=0
ARG RETRY_ATTEMPTS
ARG RETRY_DELAY_SECONDS
ARG ENABLE_USER_CONFIG
ARG ENABLE_JUPYTER_SETTINGS
ARG ENABLE_PYTHON_ENV
ARG ENABLE_R_ENV
ARG ENABLE_TEXLIVE
ARG ENABLE_QUARTO
ARG PYTHON_VERSION
ARG R_BASE_VERSION
ARG FLOWER_PYTHON_VERSION
ARG DOTFILES_REPO
ARG ENABLE_GIT_IDENTITY
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL

# Copy shell scripts
COPY shell-scripts/install-base-binaries.sh /tmp/install-base-binaries.sh
COPY shell-scripts/apply-apt-snapshot-state.sh /tmp/apply-apt-snapshot-state.sh
COPY shell-scripts/verify-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh
COPY shell-scripts/install-additional-binaries.sh /tmp/install-additional-binaries.sh
COPY shell-scripts/install-tooling-config.sh /tmp/install-tooling-config.sh
COPY shell-scripts/activate-nvim-config.sh /tmp/activate-nvim-config.sh
COPY shell-scripts/lock-additional-binaries-env.sh /tmp/lock-additional-binaries-env.sh
COPY shell-scripts/install-quarto.sh /tmp/install-quarto.sh
COPY shell-scripts/install-tinytex.sh /tmp/install-tinytex.sh
COPY shell-scripts/install-dotfiles.sh /tmp/install-dotfiles.sh
COPY shell-scripts/configure-git-identity.sh /tmp/configure-git-identity.sh
COPY shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY shell-scripts/restore-jupyterlab-settings.sh /tmp/restore-jupyterlab-settings.sh
COPY shell-scripts/install-latex-packages.sh /tmp/install-latex-packages.sh
COPY shell-scripts/install-r-packages.sh /tmp/install-r-packages.sh
COPY shell-scripts/install-python-packages.sh /tmp/install-python-packages.sh
COPY shell-scripts/configure-micromamba-shell.sh /tmp/configure-micromamba-shell.sh
COPY shell-scripts/configure-runtime-shell-env.sh /tmp/configure-runtime-shell-env.sh
COPY shell-scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY shell-scripts/export-runtime-env.sh /usr/local/bin/export-runtime-env.sh
COPY shell-scripts/lock-micromamba-env.sh /tmp/lock-micromamba-env.sh
COPY shell-scripts/lock-python-env.sh /tmp/lock-python-env.sh
COPY shell-scripts/lock-r-env.sh /tmp/lock-r-env.sh
COPY shell-scripts/lock-latex-env.sh /tmp/lock-latex-env.sh
COPY shell-scripts/lock-quarto-env.sh /tmp/lock-quarto-env.sh
COPY build-assets/ /tmp/build-assets/
COPY dotfiles-environment/ /tmp/dotfiles-environment/
COPY latex-environment/ /tmp/latex-environment/
COPY r-environment/ /tmp/r-environment/
COPY quarto-environment/ /tmp/quarto-environment/
COPY micromamba-environment/ /tmp/micromamba-environment/
COPY os-environment/ /tmp/os-environment/
COPY base-binaries-environment/ /tmp/base-binaries-environment/
COPY additional-binaries-environment/ /tmp/additional-binaries-environment/
COPY tooling-config-environment/ /tmp/tooling-config-environment/
COPY python-environment/ /tmp/python-environment/
RUN chmod +x \
  /tmp/install-base-binaries.sh \
  /tmp/apply-apt-snapshot-state.sh \
  /tmp/verify-apt-snapshot-state.sh \
  /tmp/install-dotfiles.sh \
  /tmp/configure-git-identity.sh \
  /tmp/install-additional-binaries.sh \
  /tmp/install-tooling-config.sh \
  /tmp/activate-nvim-config.sh \
  /tmp/install-quarto.sh \
  /tmp/install-tinytex.sh \
  /tmp/install-micromamba.sh \
  /tmp/restore-jupyterlab-settings.sh \
  /tmp/install-latex-packages.sh \
  /tmp/install-r-packages.sh \
  /tmp/install-python-packages.sh \
  /tmp/configure-micromamba-shell.sh \
  /tmp/configure-runtime-shell-env.sh \
  /tmp/lock-additional-binaries-env.sh \
  /tmp/lock-micromamba-env.sh \
  /tmp/lock-python-env.sh \
  /tmp/lock-r-env.sh \
  /tmp/lock-latex-env.sh \
  /tmp/lock-quarto-env.sh \
  /usr/local/bin/entrypoint.sh \
  /usr/local/bin/export-runtime-env.sh \
  && find \
  /tmp/dotfiles-environment \
  /tmp/tooling-config-environment \
  /tmp/latex-environment \
  /tmp/r-environment \
  /tmp/quarto-environment \
  /tmp/micromamba-environment \
  /tmp/os-environment \
  /tmp/base-binaries-environment \
  /tmp/additional-binaries-environment \
  /tmp/python-environment \
  -type f -exec chmod 644 {} +

# Create default non-root user
ARG USER_UID
ARG USER_GID
ARG DEV_USER_PASSWORD=

RUN groupadd --gid ${USER_GID} dev \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/sh dev

# Optional local dev password for sudo/auth flows.
RUN if [ -n "${DEV_USER_PASSWORD}" ]; then \
  echo "dev:${DEV_USER_PASSWORD}" | chpasswd; \
  fi

# Ensure home ownership and create a standard SSH config directory for optional
# host SSH config/known_hosts mounts.
RUN mkdir -p /home/dev/.ssh \
  && chmod 700 /home/dev/.ssh \
  && chown -R dev:dev /home/dev

# Install base software
RUN /tmp/apply-apt-snapshot-state.sh
RUN /tmp/install-base-binaries.sh

# Install additional software
RUN RETRY_ATTEMPTS="${RETRY_ATTEMPTS}" \
  RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS}" \
  /tmp/install-additional-binaries.sh

# Grant sudo privileges to dev user.
RUN getent group sudo >/dev/null || groupadd sudo \
  && usermod -aG sudo dev \
  && printf '%%sudo ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-sudo-group \
  && chmod 0440 /etc/sudoers.d/10-sudo-group

# Set Zsh as default shell for the non-root user
RUN chsh -s /usr/bin/zsh dev
ENV SHELL=/usr/bin/zsh

# Install user configuration layer as the non-root user.
RUN if [ "${ENABLE_USER_CONFIG}" = "true" ]; then \
  runuser -u dev -- env DOTFILES_REPO="${DOTFILES_REPO}" /tmp/install-dotfiles.sh && \
  runuser -u dev -- /tmp/install-tooling-config.sh && \
  runuser -u dev -- /tmp/activate-nvim-config.sh; \
  else \
  echo ">>> Skipping user configuration installation (ENABLE_USER_CONFIG=${ENABLE_USER_CONFIG})"; \
  fi

# Configure git
RUN runuser -u dev -- env \
  GIT_USER_NAME="${GIT_USER_NAME}" \
  GIT_USER_EMAIL="${GIT_USER_EMAIL}" \
  /tmp/configure-git-identity.sh

# Restore JupyterLab settings if enabled.
RUN if [ "${ENABLE_JUPYTER_SETTINGS}" = "true" ]; then \
  runuser -u dev -- /tmp/restore-jupyterlab-settings.sh; \
  else \
  echo ">>> Skipping JupyterLab settings restore (ENABLE_JUPYTER_SETTINGS=${ENABLE_JUPYTER_SETTINGS})"; \
  fi

# install correct micromamba based on chip architecture (user-only install)
RUN runuser -u dev -- /tmp/install-micromamba.sh
RUN chown -R dev:dev /tmp/python-environment
RUN chown -R dev:dev /tmp/r-environment

# Install python libraries
RUN if [ "${ENABLE_PYTHON_ENV}" = "true" ]; then \
  runuser -u dev -- env RETRY_ATTEMPTS="${RETRY_ATTEMPTS}" RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS}" PYTHON_VERSION="${PYTHON_VERSION}" /tmp/install-python-packages.sh; \
  else \
  echo ">>> Skipping Python environment installation (ENABLE_PYTHON_ENV=${ENABLE_PYTHON_ENV})"; \
  fi

# Install R libraries
RUN if [ "${ENABLE_R_ENV}" = "true" ]; then \
  runuser -u dev -- env RETRY_ATTEMPTS="${RETRY_ATTEMPTS}" RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS}" R_BASE_VERSION="${R_BASE_VERSION}" /tmp/install-r-packages.sh; \
  else \
  echo ">>> Skipping R environment installation (ENABLE_R_ENV=${ENABLE_R_ENV})"; \
  fi

# Enable micromamba shell integration when user-facing micromamba envs exist.
RUN if [ "${ENABLE_PYTHON_ENV}" = "true" ] || [ "${ENABLE_R_ENV}" = "true" ]; then \
  runuser -u dev -- /tmp/configure-micromamba-shell.sh; \
  else \
  echo ">>> Skipping micromamba shell initialization (ENABLE_PYTHON_ENV=${ENABLE_PYTHON_ENV}, ENABLE_R_ENV=${ENABLE_R_ENV})"; \
  fi

# Initialize runtime-derived shell environment for interactive sessions.
RUN runuser -u dev -- /tmp/configure-runtime-shell-env.sh

# Install Quarto (latest or locked) as user.
RUN if [ "${ENABLE_QUARTO}" = "true" ]; then \
  runuser -u dev -- /tmp/install-quarto.sh; \
  else \
  echo ">>> Skipping Quarto installation (ENABLE_QUARTO=${ENABLE_QUARTO})"; \
  fi

# Install TinyTeX via temporary r-environment
RUN if [ "${ENABLE_TEXLIVE}" = "true" ]; then \
  runuser -u dev -- env R_BASE_VERSION="${R_BASE_VERSION}" /tmp/install-tinytex.sh; \
  else \
  echo ">>> Skipping TinyTeX installation (ENABLE_TEXLIVE=${ENABLE_TEXLIVE})"; \
  fi

# Install additional LaTeX packages (tlmgr)
RUN if [ "${ENABLE_TEXLIVE}" = "true" ]; then \
  runuser -u dev -- /tmp/install-latex-packages.sh; \
  else \
  echo ">>> Skipping LaTeX package installation (ENABLE_TEXLIVE=${ENABLE_TEXLIVE})"; \
  fi

# Final micromamba cache cleanup to keep image size down.
RUN runuser -u dev -- env \
  MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba \
  /home/dev/.local/bin/micromamba clean --all --yes --force-pkgs-dirs

# Remove build-only files copied into /tmp during image construction.
RUN rm -rf \
  /tmp/build-assets \
  /tmp/dotfiles-environment \
  /tmp/tooling-config-environment \
  /tmp/latex-environment \
  /tmp/r-environment \
  /tmp/quarto-environment \
  /tmp/micromamba-environment \
  /tmp/os-environment \
  /tmp/base-binaries-environment \
  /tmp/additional-binaries-environment \
  /tmp/python-environment \
  /tmp/install-base-binaries.sh \
  /tmp/apply-apt-snapshot-state.sh \
  /tmp/verify-apt-snapshot-state.sh \
  /tmp/install-additional-binaries.sh \
  /tmp/install-tooling-config.sh \
  /tmp/activate-nvim-config.sh \
  /tmp/lock-additional-binaries-env.sh \
  /tmp/install-quarto.sh \
  /tmp/install-tinytex.sh \
  /tmp/install-dotfiles.sh \
  /tmp/configure-git-identity.sh \
  /tmp/install-micromamba.sh \
  /tmp/restore-jupyterlab-settings.sh \
  /tmp/install-latex-packages.sh \
  /tmp/install-r-packages.sh \
  /tmp/install-python-packages.sh \
  /tmp/configure-micromamba-shell.sh \
  /tmp/configure-runtime-shell-env.sh \
  /tmp/lock-micromamba-env.sh \
  /tmp/lock-python-env.sh \
  /tmp/lock-r-env.sh \
  /tmp/lock-latex-env.sh \
  /tmp/lock-quarto-env.sh

# Runtime image defaults and runtime tool environment are defined here. Dynamic
# tool-path variables for optional components are added by
# /usr/local/bin/export-runtime-env.sh, sourced by the entrypoint.
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}
ENV BASE_BINARIES_LOCKED=${BASE_BINARIES_LOCKED}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba
ENV PATH=/home/dev/.local/bin:$PATH

# Set working directory
WORKDIR /home/dev

# Switch to non-root user
USER dev

# Start Zsh login shell by default
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh", "-l"]

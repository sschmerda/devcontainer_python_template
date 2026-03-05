# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

USER root
ARG DEV_ENV_LOCKED=0
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}
ARG PYTHON_VERSION
ARG R_BASE_VERSION
ARG FLOWER_PYTHON_VERSION
ARG DOTFILES_REPO
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV R_BASE_VERSION=${R_BASE_VERSION}
ENV FLOWER_PYTHON_VERSION=${FLOWER_PYTHON_VERSION}
ENV DOTFILES_REPO=${DOTFILES_REPO}

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
COPY shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY shell-scripts/restore-jupyterlab-settings.sh /tmp/restore-jupyterlab-settings.sh
COPY shell-scripts/install-latex-packages.sh /tmp/install-latex-packages.sh
COPY shell-scripts/install-r-packages.sh /tmp/install-r-packages.sh
COPY shell-scripts/install-python-packages.sh /tmp/install-python-packages.sh
COPY shell-scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
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
COPY additional-binaries-environment/ /tmp/additional-binaries-environment/
COPY tooling-config-environment/ /tmp/tooling-config-environment/
COPY python-environment/ /tmp/python-environment/
RUN chmod +x /tmp/install-base-binaries.sh /tmp/apply-apt-snapshot-state.sh /tmp/verify-apt-snapshot-state.sh /tmp/install-dotfiles.sh /tmp/install-additional-binaries.sh /tmp/install-tooling-config.sh /tmp/activate-nvim-config.sh /tmp/install-quarto.sh /tmp/install-tinytex.sh /tmp/install-micromamba.sh /tmp/restore-jupyterlab-settings.sh /tmp/install-latex-packages.sh /tmp/install-r-packages.sh /tmp/install-python-packages.sh /tmp/lock-additional-binaries-env.sh /tmp/lock-micromamba-env.sh /tmp/lock-python-env.sh /tmp/lock-r-env.sh /tmp/lock-latex-env.sh /tmp/lock-quarto-env.sh /usr/local/bin/entrypoint.sh

# Install base software
RUN /tmp/apply-apt-snapshot-state.sh
RUN /tmp/install-base-binaries.sh  
# Install additional software
RUN /tmp/install-additional-binaries.sh

# locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create default non-root user
ARG USER_UID
ARG USER_GID
ARG DEV_USER_PASSWORD=

RUN groupadd --gid ${USER_GID} dev \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /usr/bin/zsh dev

# Optional local dev password for sudo/auth flows.
RUN if [ -n "${DEV_USER_PASSWORD}" ]; then \
  echo "dev:${DEV_USER_PASSWORD}" | chpasswd; \
  fi

# Grant sudo privileges to dev user.
RUN getent group sudo >/dev/null || groupadd sudo \
  && usermod -aG sudo dev \
  && printf '%%sudo ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-sudo-group \
  && chmod 0440 /etc/sudoers.d/10-sudo-group

# Set Zsh as default shell for the non-root user
RUN chsh -s /usr/bin/zsh dev
ENV SHELL=/usr/bin/zsh

# Ensure home ownership
RUN chown -R dev:dev /home/dev

# Install dotfiles as the non-root user (correct HOME)
RUN su - dev -c "DOTFILES_REPO=${DOTFILES_REPO} /tmp/install-dotfiles.sh"
RUN su - dev -c "/tmp/activate-nvim-config.sh"

# Install user-level binaries/config after dotfiles
RUN su - dev -c "/tmp/install-tooling-config.sh"
RUN su - dev -c "/tmp/restore-jupyterlab-settings.sh"

# install correct micromamba based on chip architecture (user-only install)
RUN su - dev -c "/tmp/install-micromamba.sh"
RUN chown -R dev:dev /tmp/python-environment
RUN chown -R dev:dev /tmp/r-environment

# Install python libraries
RUN su - dev -c "PYTHON_VERSION=${PYTHON_VERSION} /tmp/install-python-packages.sh"

# Install R libraries
RUN su - dev -c "R_BASE_VERSION=${R_BASE_VERSION} /tmp/install-r-packages.sh"

# Install Quarto (latest or locked) as user.
RUN su - dev -c "/tmp/install-quarto.sh"

# Install TinyTeX via temporary r-environment
RUN su - dev -c "R_BASE_VERSION=${R_BASE_VERSION} /tmp/install-tinytex.sh"

# Install additional LaTeX packages (tlmgr)
RUN su - dev -c "/tmp/install-latex-packages.sh"

# Final micromamba cache cleanup to keep image size down.
RUN su - dev -c "MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba /home/dev/.local/bin/micromamba clean --all --yes --force-pkgs-dirs"

ENV MAMBA_DEFAULT_ENV=python-env
ENV MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba
ENV QUARTO_PYTHON=/home/dev/.local/share/mamba/envs/python-env/bin/python
ENV QUARTO_JUPYTER=/home/dev/.local/share/mamba/envs/python-env/bin/jupyter
ENV QUARTO_R=/home/dev/.local/share/mamba/envs/r-env/bin/R
ENV RETICULATE_PYTHON=/home/dev/.local/share/mamba/envs/python-env/bin/python
ENV PATH=/home/dev/.local/bin:$PATH

# Set working directory
WORKDIR /home/dev

# Switch to non-root user
USER dev

# Start Zsh login shell by default
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh", "-l"]

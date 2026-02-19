# check=skip=InvalidDefaultArgInFrom
ARG DEVCONTAINER_OS_IMAGE
FROM ${DEVCONTAINER_OS_IMAGE}

USER root

# Copy shell scripts
COPY shell-scripts/install-base-binaries.sh /tmp/install-base-binaries.sh
COPY shell-scripts/install-additional-binaries-root.sh /tmp/install-additional-binaries-root.sh
COPY shell-scripts/install-additional-binaries-user.sh /tmp/install-additional-binaries-user.sh
COPY shell-scripts/install-quarto.sh /tmp/install-quarto.sh
COPY shell-scripts/install-quarto-lock.sh /tmp/install-quarto-lock.sh
COPY shell-scripts/install-tinytex.sh /tmp/install-tinytex.sh
COPY shell-scripts/install-dotfiles.sh /tmp/install-dotfiles.sh
COPY shell-scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY shell-scripts/restore-jupyterlab-settings.sh /tmp/restore-jupyterlab-settings.sh
COPY shell-scripts/install-latex-packages.sh /tmp/install-latex-packages.sh
COPY shell-scripts/install-latex-packages-lock.sh /tmp/install-latex-packages-lock.sh
COPY shell-scripts/install-r-packages.sh /tmp/install-r-packages.sh
COPY shell-scripts/install-r-packages-lock.sh /tmp/install-r-packages-lock.sh
COPY shell-scripts/install-python-packages.sh /tmp/install-python-packages.sh
COPY shell-scripts/install-python-packages-lock.sh /tmp/install-python-packages-lock.sh
COPY shell-scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY shell-scripts/lock-mamba-env.sh /tmp/lock-mamba-env.sh
COPY shell-scripts/lock-r-env.sh /tmp/lock-r-env.sh
COPY shell-scripts/lock-latex-env.sh /tmp/lock-latex-env.sh
COPY shell-scripts/lock-quarto-env.sh /tmp/lock-quarto-env.sh
COPY build-assets/ /tmp/build-assets/
COPY latex-environment/ /tmp/latex-environment/
COPY r-environment/ /tmp/r-environment/
COPY quarto-environment/ /tmp/quarto-environment/
COPY python-environment/ /tmp/python-environment/
RUN chmod +x /tmp/install-base-binaries.sh /tmp/install-dotfiles.sh /tmp/install-additional-binaries-root.sh /tmp/install-additional-binaries-user.sh /tmp/install-quarto.sh /tmp/install-quarto-lock.sh /tmp/install-tinytex.sh /tmp/install-micromamba.sh /tmp/restore-jupyterlab-settings.sh /tmp/install-latex-packages.sh /tmp/install-latex-packages-lock.sh /tmp/install-r-packages.sh /tmp/install-r-packages-lock.sh /tmp/install-python-packages.sh /tmp/install-python-packages-lock.sh /tmp/lock-mamba-env.sh /tmp/lock-r-env.sh /tmp/lock-latex-env.sh /tmp/lock-quarto-env.sh /usr/local/bin/entrypoint.sh

# Install base software
RUN /tmp/install-base-binaries.sh  
# Install additional software
RUN /tmp/install-additional-binaries-root.sh

# locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create default non-root user
ARG USER_UID
ARG USER_GID

RUN groupadd --gid ${USER_GID} dev \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /usr/bin/zsh dev

# Set Zsh as default shell for the non-root user
RUN chsh -s /usr/bin/zsh dev
ENV SHELL=/usr/bin/zsh

# Ensure home ownership
RUN chown -R dev:dev /home/dev

# Install dotfiles as the non-root user (correct HOME)
RUN su - dev -c "/tmp/install-dotfiles.sh"

# Install user-level binaries/config after dotfiles
RUN su - dev -c "/tmp/install-additional-binaries-user.sh"
RUN su - dev -c "/tmp/restore-jupyterlab-settings.sh"

# install correct micromamba based on chip architecture (user-only install)
RUN su - dev -c "/tmp/install-micromamba.sh"
RUN chown -R dev:dev /tmp/python-environment
RUN chown -R dev:dev /tmp/r-environment

ARG DEV_ENV_LOCKED=0
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}

# Install python libraries
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-python-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-python-packages.sh"; \
  fi

# Install R libraries
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-r-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-r-packages.sh"; \
  fi

# Install Quarto (latest or locked) as user.
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-quarto-lock.sh"; \
  else \
  su - dev -c "/tmp/install-quarto.sh"; \
  fi

# Install TinyTeX via temporary r-environment
RUN su - dev -c "/tmp/install-tinytex.sh"

# Install additional LaTeX packages (tlmgr)
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-latex-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-latex-packages.sh"; \
  fi

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

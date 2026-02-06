# FROM ubuntu:24.04
FROM debian:13-slim

USER root

# Copy shell scripts
COPY shell_scripts/install-base-binaries.sh /tmp/install-base-binaries.sh
COPY shell_scripts/install-additional-binaries-root.sh /tmp/install-additional-binaries-root.sh
COPY shell_scripts/install-additional-binaries-user.sh /tmp/install-additional-binaries-user.sh
COPY shell_scripts/install-tinytex.sh /tmp/install-tinytex.sh
COPY shell_scripts/install-dotfiles.sh /tmp/install-dotfiles.sh
COPY shell_scripts/install-micromamba.sh /tmp/install-micromamba.sh
COPY shell_scripts/restore-jupyterlab-settings.sh /tmp/restore-jupyterlab-settings.sh
COPY shell_scripts/install-latex-packages.sh /tmp/install-latex-packages.sh
COPY shell_scripts/install-latex-packages-lock.sh /tmp/install-latex-packages-lock.sh
COPY shell_scripts/install-r-packages.sh /tmp/install-r-packages.sh
COPY shell_scripts/install-r-packages-lock.sh /tmp/install-r-packages-lock.sh
COPY shell_scripts/install-python-packages.sh /tmp/install-python-packages.sh
COPY shell_scripts/install-python-packages-lock.sh /tmp/install-python-packages-lock.sh
COPY shell_scripts/lock-mamba-env.sh /tmp/lock-mamba-env.sh
COPY shell_scripts/lock-r-env.sh /tmp/lock-r-env.sh
COPY shell_scripts/lock-latex-env.sh /tmp/lock-latex-env.sh
COPY build_assets/ /tmp/build_assets/
COPY latex-environment/ /tmp/latex-environment/
COPY r-environment/ /tmp/r-environment/
COPY mamba_environment/ /tmp/mamba_environment/
RUN chmod +x /tmp/install-base-binaries.sh /tmp/install-dotfiles.sh /tmp/install-additional-binaries-root.sh /tmp/install-additional-binaries-user.sh /tmp/install-tinytex.sh /tmp/install-micromamba.sh /tmp/restore-jupyterlab-settings.sh /tmp/install-latex-packages.sh /tmp/install-latex-packages-lock.sh /tmp/install-r-packages.sh /tmp/install-r-packages-lock.sh /tmp/install-python-packages.sh /tmp/install-python-packages-lock.sh /tmp/lock-mamba-env.sh /tmp/lock-r-env.sh /tmp/lock-latex-env.sh

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
ARG DEV_ENV_LOCKED=0
ENV DEV_ENV_LOCKED=${DEV_ENV_LOCKED}
RUN su - dev -c "/tmp/install-micromamba.sh"
RUN chown -R dev:dev /tmp/mamba_environment
RUN chown -R dev:dev /tmp/r-environment

# Install python libraries
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-python-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-python-packages.sh"; \
  fi

# Install additional LaTeX packages (tlmgr)
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-latex-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-latex-packages.sh"; \
  fi
# Install R libraries
RUN if [ "$DEV_ENV_LOCKED" = "1" ]; then \
  su - dev -c "/tmp/install-r-packages-lock.sh"; \
  else \
  su - dev -c "/tmp/install-r-packages.sh"; \
  fi

ENV MAMBA_DEFAULT_ENV=python-env
ENV MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba
ENV PATH=/home/dev/.local/bin:$PATH

# Set working directory
WORKDIR /home/dev

# Switch to non-root user
USER dev

# Start Zsh login shell by default
CMD ["zsh", "-l"]

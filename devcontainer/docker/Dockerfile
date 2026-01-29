# FROM ubuntu:24.04
FROM debian:13-slim

USER root

# Copy shell scripts
COPY docker/install-base-binaries.sh /tmp/install-base-binaries.sh
COPY docker/install-additional-binaries-root.sh /tmp/install-additional-binaries-root.sh
COPY docker/install-additional-binaries-user.sh /tmp/install-additional-binaries-user.sh
COPY docker/install-dotfiles.sh /tmp/install-dotfiles.sh
COPY docker/install-micromamba.sh /tmp/install-micromamba.sh
COPY shell_scripts/restore-jupyterlab-settings.sh /tmp/restore-jupyterlab-settings.sh
COPY shell_scripts/install-latex-packages.sh /tmp/install-latex-packages.sh
COPY build_assets/ /tmp/build_assets/
COPY latex-environment/ /tmp/latex-environment/
COPY mamba_environment/ /tmp/mamba_environment/
RUN chmod +x /tmp/install-base-binaries.sh /tmp/install-dotfiles.sh /tmp/install-additional-binaries-root.sh /tmp/install-additional-binaries-user.sh /tmp/install-micromamba.sh /tmp/restore-jupyterlab-settings.sh /tmp/install-latex-packages.sh

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
ARG MAMBA_ENV_FILE=mamba_environment/environment.yml
ENV MAMBA_ENV_FILE=/tmp/${MAMBA_ENV_FILE}
RUN chown -R dev:dev /tmp/mamba_environment
RUN su - dev -c "MAMBA_ENV_FILE=${MAMBA_ENV_FILE} /tmp/install-micromamba.sh"

# Install additional LaTeX packages (tlmgr)
RUN su - dev -c "/tmp/install-latex-packages.sh"

ENV MAMBA_DEFAULT_ENV=dev
ENV MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba
ENV PATH=/home/dev/.local/bin:$PATH

# Set working directory
WORKDIR /home/dev

# Switch to non-root user
USER dev

# Start Zsh login shell by default
CMD ["zsh", "-l"]

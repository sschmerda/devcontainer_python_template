# FROM ubuntu:24.04
FROM debian:13-slim

USER root

# Copy shell scripts
COPY install-base-binaries.sh /tmp/install-base-binaries.sh
COPY install-additional-binaries-root.sh /tmp/install-additional-binaries-root.sh
COPY install-additional-binaries-user.sh /tmp/install-additional-binaries-user.sh
COPY install-dotfiles.sh /tmp/install-dotfiles.sh
COPY install-micromamba.sh /tmp/install-micromamba.sh
COPY environment.yml /tmp/environment.yml
RUN chmod +x /tmp/install-base-binaries.sh /tmp/install-dotfiles.sh /tmp/install-additional-binaries-root.sh /tmp/install-additional-binaries-user.sh /tmp/install-micromamba.sh

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

# install correct micromamba based on chip architecture (user-only install)
RUN su - dev -c "/tmp/install-micromamba.sh"

ENV MAMBA_DEFAULT_ENV=dev
ENV MAMBA_ROOT_PREFIX=/home/dev/.local/share/mamba
ENV PATH=/home/dev/.local/bin:$PATH

# Set working directory
WORKDIR /home/dev

# Switch to non-root user
USER dev

# Start Zsh login shell by default
CMD ["zsh", "-l"]

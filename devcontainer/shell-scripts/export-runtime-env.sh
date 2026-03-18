#!/usr/bin/env bash
set -euo pipefail

# Runtime tool locations are derived from the installed environments so optional
# components only export variables when their executables actually exist.
mamba_root_prefix="${MAMBA_ROOT_PREFIX:?MAMBA_ROOT_PREFIX is not set.}"
python_env_bin="${mamba_root_prefix}/envs/python-env/bin"
r_env_bin="${mamba_root_prefix}/envs/r-env/bin"

# TinyTeX commonly installs TeX binaries into $HOME/bin.
if [ -d "${HOME}/bin" ]; then
  export PATH="${HOME}/bin:${PATH}"
fi

# Clear any inherited values first so disabled/missing environments do not leave
# stale runtime paths behind.
unset QUARTO_PYTHON QUARTO_JUPYTER QUARTO_R RETICULATE_PYTHON

if [ -x "${python_env_bin}/python" ]; then
  export QUARTO_PYTHON="${python_env_bin}/python"
  export RETICULATE_PYTHON="${python_env_bin}/python"
fi

if [ -x "${python_env_bin}/jupyter" ]; then
  export QUARTO_JUPYTER="${python_env_bin}/jupyter"
fi

if [ -x "${r_env_bin}/R" ]; then
  export QUARTO_R="${r_env_bin}/R"
fi

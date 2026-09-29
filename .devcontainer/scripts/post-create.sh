#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

if ! git submodule update --init --recursive; then
  git config submodule."dot_config/nano/nanorc.d".url "https://github.com/scopatz/nanorc.git"
  git submodule sync --recursive
  git submodule update --init --recursive
fi

chezmoi apply --source="$REPO_ROOT"

if [ -d .venv ] && [ ! -x .venv/bin/python ]; then
  rm -rf .venv
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

.venv/bin/python -m ensurepip --upgrade
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install behave pynvim

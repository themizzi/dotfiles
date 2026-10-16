#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

if { [ -e .venv ] || [ -L .venv ]; } && { [ ! -d .venv ] || [ ! -x .venv/bin/python ]; }; then
  printf '%s\n' 'Existing .venv is not a usable virtual environment. Inspect and move it aside explicitly before retrying; it has not been deleted.' >&2
  exit 1
fi

if ! git submodule update --init --recursive; then
  git config submodule."nano/.config/nano/nanorc.d".url "https://github.com/scopatz/nanorc.git"
  git submodule sync --recursive
  git submodule update --init --recursive
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

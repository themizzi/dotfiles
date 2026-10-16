#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

if ! git submodule update --init --recursive; then
  git config submodule."nano/.config/nano/nanorc.d".url "https://github.com/scopatz/nanorc.git"
  git submodule sync --recursive
  git submodule update --init --recursive
fi

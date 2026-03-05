#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

rm -f \
  "$HOME/.config/gh/config.yml" \
  "$HOME/.stowrc-gh" \
  "$HOME/.config/gh-copilot/config.yml" \
  "$HOME/.muttrc" \
  "$HOME/.config/nano/nanorc" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/task/taskrc" \
  "$HOME/.config/tmux/tmux.conf" \
  "$HOME/.config/zellij/config.kdl" \
  "$HOME/.config/zellij/layouts/default.kdl" \
  "$HOME/.zsh_plugins.txt" \
  "$HOME/.zshenv" \
  "$HOME/.zshrc"

if ! git submodule update --init --recursive; then
  git config submodule."nano/.config/nano/nanorc.d".url "https://github.com/scopatz/nanorc.git"
  git submodule sync --recursive
  git submodule update --init --recursive
fi

if [ -d .venv ] && [ ! -x .venv/bin/python ]; then
  rm -rf .venv
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

.venv/bin/python -m ensurepip --upgrade
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install behave pynvim

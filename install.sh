#!/usr/bin/env sh
set -eu

stow --restow --target="$HOME" --no-folding gh gh-copilot mutt nano nvim starship task tmux vim zsh

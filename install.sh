#!/usr/bin/env sh
set -eu

stow --restow --target="$HOME" --no-folding gh gh-copilot nano nvim starship vim zsh

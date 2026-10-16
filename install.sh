#!/usr/bin/env sh
set -eu

stow --restow --target="$HOME" --no-folding gh gh-copilot hypr hyprshell nano nvim starship systemd toshy vim zsh

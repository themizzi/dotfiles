#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$ROOT"

case "$(uname -s)" in
    Darwin)
        command -v brew >/dev/null 2>&1 || { echo 'dev setup: install Homebrew first' >&2; exit 1; }
        brew install git stow zsh python jq shellcheck stylua neovim
        ;;
    Linux)
        if [ "$(id -u)" -eq 0 ]; then
            SUDO=
        else
            command -v sudo >/dev/null 2>&1 || { echo 'dev setup: sudo is required' >&2; exit 1; }
            SUDO=sudo
        fi
        if command -v apt-get >/dev/null 2>&1; then
            if [ "$(uname -m)" != x86_64 ]; then
                echo 'dev setup: automatic Debian/Ubuntu tool installation requires x86_64; install prerequisites manually on this architecture' >&2
                exit 1
            fi
            $SUDO apt-get update
            $SUDO apt-get install -y git stow zsh python3 jq shellcheck procps
            # Debian and Ubuntu may lack a recent Neovim or a StyLua package.
            # Reuse the checksum-verified CI releases in a user-owned directory.
            tools_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-dev-tools"
            mkdir -p "$tools_dir"
            RUNNER_TEMP="$tools_dir" GITHUB_PATH="$tools_dir/paths" python3 -B .github/workflows/install-tools.py
            printf '\n%s\n' "Add these directories to PATH before running checks and tests:" \
                "  $tools_dir/dotfiles-tools/nvim-linux-x86_64/bin" \
                "  $tools_dir/dotfiles-tools"
        elif command -v pacman >/dev/null 2>&1; then
            $SUDO pacman -Syu --needed git stow zsh python jq shellcheck stylua neovim procps-ng
        else
            echo 'dev setup: supported package manager not found (apt-get or pacman)' >&2
            exit 1
        fi
        ;;
    *)
        echo 'dev setup: supported systems are macOS, Debian/Ubuntu, and Arch Linux' >&2
        exit 1
        ;;
esac

git submodule update --init --recursive -- vendor
echo 'dev setup: complete'

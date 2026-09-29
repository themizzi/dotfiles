#!/usr/bin/env sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v chezmoi >/dev/null 2>&1; then
    printf '%s\n' "chezmoi is required; install it before running install.sh." >&2
    exit 1
fi

chezmoi apply --source="$REPO_ROOT" --destination="$HOME" "$@"

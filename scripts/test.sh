#!/bin/sh
# Offline Bats suite using only the reviewed vendor submodules.
set -eu
unset BASH_ENV ENV BATS_ROOT BATS_LIBDIR BATS_BASE_LIBDIR BATS_LIB_PATH
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
for file in vendor/bats-core/bin/bats vendor/bats-support/load.bash vendor/bats-assert/load.bash; do
    if [ ! -r "$ROOT/$file" ]; then
        printf 'test: missing %s; initialize pinned dependencies with:\n  git -C "%s" submodule update --init --recursive -- vendor\n' "$file" "$ROOT" >&2
        exit 1
    fi
done
for executable in bash nvim stow zsh git just; do
    if ! command -v "$executable" >/dev/null 2>&1; then
        printf 'test: required executable not found: %s\n' "$executable" >&2
        exit 1
    fi
done
version=$(nvim --version | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
if [ -z "$version" ] || ! printf '%s\n' "$version" | awk -F. '{ exit !($1 > 0 || $2 > 11 || ($2 == 11 && $3 >= 3)) }'; then
    printf '%s\n' 'test: Neovim 0.11.3+ is required' >&2
    exit 1
fi
BATS_TEST_TIMEOUT=${BATS_TEST_TIMEOUT:-30}
export BATS_TEST_TIMEOUT
exec bash "$ROOT/vendor/bats-core/bin/bats" "$@" "$ROOT/test"

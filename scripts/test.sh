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
exec bash "$ROOT/vendor/bats-core/bin/bats" "$@" "$ROOT/test"

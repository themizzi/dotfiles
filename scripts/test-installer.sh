#!/bin/sh
# Offline, Python-free entry point using the reviewed Bats submodules.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
for file in vendor/bats-core/bin/bats vendor/bats-support/load.bash vendor/bats-assert/load.bash; do
    if [ ! -r "$ROOT/$file" ]; then
        printf 'test-installer: missing %s; initialize pinned dependencies with:\n  git -C "%s" submodule update --init --recursive -- vendor\n' "$file" "$ROOT" >&2
        exit 1
    fi
done
for executable in bash git stow; do
    if ! command -v "$executable" >/dev/null 2>&1; then
        printf 'test-installer: required executable not found: %s\n' "$executable" >&2
        exit 1
    fi
done
BATS_TEST_TIMEOUT=${BATS_TEST_TIMEOUT:-30}
export BATS_TEST_TIMEOUT
exec bash "$ROOT/vendor/bats-core/bin/bats" "$@" "$ROOT/test/installer.bats"

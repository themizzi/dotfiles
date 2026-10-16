set shell := ["sh", "-eu", "-c"]
set positional-arguments

# Install dotfiles; forward arguments unchanged to the supported shell entry point.
install *args:
    sh install.sh "$@"

# Parse source files without installing, sourcing config, or writing bytecode.
check:
    sh scripts/check.sh

# Run the pinned installer suite without Python or a venv.
test-installer *args:
    sh scripts/test-installer.sh "$@"

# Run Bats and standalone standard-library tests without fetching dependencies.
test:
    #!/bin/sh
    set -eu
    python=.venv/bin/python
    if [ ! -x "$python" ]; then
        echo 'test: missing .venv/bin/python; create it with python3 -m venv .venv (see docs/just.md)' >&2
        exit 1
    fi
    export PYTHONDONTWRITEBYTECODE=1
    for executable in nvim stow zsh; do
        if ! command -v "$executable" >/dev/null 2>&1; then
            echo "test: required executable not found in PATH: $executable" >&2
            exit 1
        fi
    done
    sh scripts/test-installer.sh
    "$python" -B -m unittest discover -s test -p 'test_*.py'

set shell := ["sh", "-eu", "-c"]
set positional-arguments

# Install dotfiles; forward arguments unchanged to the supported shell entry point.
install *args:
    sh install.sh "$@"

# Parse source files without installing, sourcing config, or writing bytecode.
check:
    sh scripts/check.sh

# Run local stdlib tests (when present), then the Behave suite.
test:
    #!/bin/sh
    set -eu
    python=.venv/bin/python
    if [ ! -x "$python" ]; then
        echo 'test: missing .venv/bin/python; create .venv and install behave and pynvim (see docs/just.md)' >&2
        exit 1
    fi
    export PYTHONDONTWRITEBYTECODE=1
    if [ -d test ]; then
        "$python" -B -m unittest discover -s test -p 'test_*.py'
    fi
    "$python" -B -c 'import importlib.util, sys; missing = [name for name in ("behave", "pynvim") if importlib.util.find_spec(name) is None]; sys.exit("test: missing .venv dependencies: " + ", ".join(missing) + "; see docs/just.md") if missing else None'
    for executable in nvim stow zsh; do
        if ! command -v "$executable" >/dev/null 2>&1; then
            echo "test: required executable not found in PATH: $executable" >&2
            exit 1
        fi
    done
    "$python" -B -m behave

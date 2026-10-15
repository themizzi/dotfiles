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

# Run all pinned Bats suites without Python or fetching dependencies.
# Lint executable shell scripts without sourcing or running them.
lint:
    @command -v shellcheck >/dev/null 2>&1 || { echo 'lint: ShellCheck is required; install the dev dependencies' >&2; exit 1; }
    shellcheck install.sh scripts/*.sh .devcontainer/scripts/*.sh

test *args:
    sh scripts/test.sh "$@"

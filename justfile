set shell := ["sh", "-eu", "-c"]
set positional-arguments

# Install dotfiles; forward arguments unchanged to the supported shell entry point.
install *args:
    sh install.sh "$@"

# Validate source syntax, shell lint, and Lua formatting without rewriting files.
check:
    @for tool in git zsh python3 jq shellcheck stylua; do command -v "$tool" >/dev/null 2>&1 || { echo "check: $tool is required; see docs/testing.md" >&2; exit 1; }; done
    shellcheck install.sh scripts/*.sh .devcontainer/scripts/*.sh .github/workflows/*.sh
    shellcheck --shell=bash test/helpers/*.bash
    git ls-files -z --cached --others --exclude-standard -- '*.zsh' '**/.zshrc' '**/.zshenv' '**/.zprofile' '**/.zlogin' '**/.zlogout' | xargs -0 -n 1 sh -c '[ "$#" -eq 0 ] || [ ! -f "$1" ] || exec zsh -f -n "$1"' sh
    git ls-files -z --cached --others --exclude-standard -- '*.json' | xargs -0 -n 1 sh -c '[ "$#" -eq 0 ] || [ ! -f "$1" ] || exec jq -e -s '"'"'length == 1'"'"' "$1" >/dev/null' sh
    git ls-files -z --cached --others --exclude-standard -- '*.py' | xargs -0 -n 1 sh -c '[ "$#" -eq 0 ] || [ ! -f "$1" ] || exec python3 -B -c '"'"'import ast, sys, tokenize; f = tokenize.open(sys.argv[1]); ast.parse(f.read(), filename=sys.argv[1])'"'"' "$1"' sh
    stylua --check nvim/.config/nvim test/neovim

# Run the pinned installer suite without Python or a venv.
test-installer *args:
    sh scripts/test-installer.sh "$@"

# Run all pinned Bats suites without Python or fetching dependencies.
test *args:
    sh scripts/test.sh "$@"

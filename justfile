set shell := ["sh", "-eu", "-c"]
set positional-arguments

# Developer setup and validation.
mod dev

# Install dotfiles; forward arguments unchanged to the supported shell entry point.
install *args:
    sh install.sh "$@"

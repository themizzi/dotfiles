# Just tasks

Run these commands from the repository root. Just also finds the `justfile`
from subdirectories and runs recipes in its directory. Paths containing spaces
are supported; recipes use POSIX `sh`, not Bash-specific syntax.

Install [Just](https://just.systems/) separately (`brew install just` on macOS,
or `sudo apt-get install just` on Debian releases providing the package).
Neither checks nor tests install tools, fetch plugins, or bootstrap a venv.

## Install

```sh
just install
```

This runs `sh install.sh`. `just install ARG...` forwards each argument unchanged,
including spaces, to that script. For example, `just install --dry-run` previews
the link operation and `just install --unlink` removes only managed links.
GNU Stow is required. You can still run `sh install.sh` without installing Just.
Installation modifies home-directory symlinks; it is not a check.

## Check

```sh
just check
```

Requires Git, Zsh, Python 3, jq, ShellCheck, and StyLua in `PATH`. It checks
shell scripts with ShellCheck, Zsh syntax with `zsh -f -n`, strict JSON with jq,
Python syntax with the standard library, and Lua formatting with StyLua. Git
selects tracked and new unignored Zsh, JSON, and Python files without entering
submodules. These checks do not execute configuration, write bytecode, rewrite
files, install dotfiles, or access the network. See [testing tools](testing.md)
for prerequisites and optional prek hook installation.

## Test

`just test-installer` runs pinned Bats installer tests without Python or a venv.
Initialize `vendor/` explicitly with `git submodule update --init --recursive -- vendor`;
the recipe never installs or fetches dependencies. It forwards Bats options,
for example `just test-installer --filter 'real Stow'`. Bash, Git, and Stow are
required; system Bats and helper packages are not used.
Run all Bats suites with:

```sh
just test
```

The runner uses the pinned Bats submodules and never downloads dependencies.
Arguments are forwarded to Bats, for example `just test --filter 'just task'`.
Test fixtures use disposable directories and do not modify the host configuration.
No Python test interpreter is needed. No Makefile is needed.

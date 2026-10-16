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
# Without Just:
sh scripts/check.sh
```

Requires `sh`, `zsh`, `python3`, and `git` in `PATH`, with an explicit error if
one is missing. Checks tracked and new unignored files using `sh -n`, `zsh -f -n`,
JSON parsing, and Python AST parsing. It skips ignored files and submodule
contents. It does not source shell configuration, import repository Python
modules, compile bytecode, install dotfiles, or access the network. This is a
syntax check, not a semantic/configuration validator. JSON must be strict JSON.

## Test

`just test-installer` runs pinned Bats installer tests without Python or a venv.
Initialize `vendor/` explicitly with `git submodule update --init --recursive -- vendor`;
the recipe never installs or fetches dependencies. It forwards Bats options,
for example `just test-installer --filter 'real Stow'`. Bash, Git, and Stow are
required; system Bats and helper packages are not used.

Set up dependencies explicitly before testing:

```sh
python3 -m venv .venv
just test
```

`just test` runs the pinned Bats installer suite, then `.venv/bin/python` for
standard-library unittest discovery in `test/`. Missing venv or required runtime
tools (`nvim`, `stow`, `zsh`) produce explicit diagnostics. No third-party Python
packages are required, and nothing is installed automatically. Editor tests use
isolated headless processes with plugin bootstrap disabled.

Run an individual Python test module using unittest discovery's `-p` option.
Run only task-contract unit tests without third-party dependencies using:

```sh
python3 -B -m unittest discover -s test -p 'test_just.py'
```

Execution contract tests skip when Just is unavailable. No Makefile is needed.

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

Set up dependencies explicitly before testing:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install behave pynvim
just test
```

`just test` uses only `.venv/bin/python`, first running stdlib unittest discovery
in `test/` (when present), then `python -m behave`. Missing venv, Python packages,
or required runtime tools (`nvim`, `stow`, `zsh`) produce explicit diagnostics;
nothing is installed automatically. Behave uses the repository's existing
fixtures and temporary homes, with plugin bootstrap disabled by those fixtures.
The recipe itself performs no network/bootstrap step. Other tools or plugin
availability may still be required by individual scenarios.

Run an individual feature directly with `.venv/bin/python -m behave features/NAME.feature`.
Run only task-contract unit tests without third-party dependencies using:

```sh
python3 -B -m unittest discover -s test -p 'test_just.py'
```

Execution contract tests skip when Just is unavailable. No Makefile is needed.

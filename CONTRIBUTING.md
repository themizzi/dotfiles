# Contributing

## Setup

Install Just 1.31.0 or newer and Git first, then run:

```sh
just dev setup
```

This installs the tools for checks and tests and initializes the pinned Bats
submodules. It requires network access and a package manager: Homebrew on
macOS, apt on Debian/Ubuntu, or pacman on Arch. Linux may require sudo; Arch
performs a full system upgrade. On Debian/Ubuntu, automatic setup supports
x86_64 and prints two directories to add to your PATH for Neovim and StyLua.
On other architectures, install the tools manually.

For manual setup, install Bash, Git, GNU Stow, Zsh, Python 3, jq, ShellCheck,
StyLua, Neovim >= 0.12, and `ps`/`pkill`, then run
`git submodule update --init --recursive -- vendor`.

## Commands

```sh
just dev check                    # shell lint, zsh/python syntax, JSON, Lua format
just dev test                     # all Bats suites
just dev test --filter 'profile'  # forward any Bats option
```

Tests run against disposable HOME/XDG directories and never modify your host
configuration or download dependencies. If `vendor/` submodules are missing,
setup fails with an explicit instruction; tests never fetch them.

Install [prek](https://prek.j178.dev/installation/) and run
`prek -c .pre-commit-config.yaml install` once per clone to run `just dev test`
before each push. The hook requires the test prerequisites and initialized Bats
submodules described above; a failing test prevents the push. Run `just dev check`
separately for lint and formatting.

## Data files

Edit these sources of truth instead of duplicating lists in code:

- `packages/cli.tsv` — canonical CLI mapping (group, command, apt, pacman, brew; `-` = not provided).
- `profiles/packages` — allowlist of stowable packages.
- `profiles/NAME.profile` — two-field declarative entries: `extends`, `package`, `cli-group`, `macos-bundle`.
- `packages/Brewfile.<name>` — macOS application bundles per name.
- `Aptfile` — generated snapshot; regenerate with:

```sh
bash scripts/packages.sh --manager apt --list > Aptfile
```

## Conventions

- Scripts and just recipes use POSIX `sh`, not Bash-specific syntax, and must
  work on Bash 3.2.
- Paths with spaces must work everywhere.
- Scripts pass arguments as arrays and parse data files; never `eval` data.
- Tests are Bats only: no Python test frameworks, no venv.

## CI

CI runs the full Bats suite on Ubuntu and macOS (installer suite with system
Bash 3.2), plus Debian 13 and Arch containers. The network-dependent plugin
smoke is a separate opt-in job: Actions → Validation → Run workflow →
`plugin_startup`, or `sh .github/workflows/plugin-smoke.sh`. WSL support is
verified manually with a real WSL2 environment.

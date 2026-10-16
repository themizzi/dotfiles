# Testing

## Bats-only test suite

Initialize the pinned test tools explicitly (the first command may use the network), then run:

```sh
git submodule update --init --recursive -- vendor
just test
```

`just test` invokes `scripts/test.sh`, which runs every suite with vendored Bats
v1.14.0, bats-support v0.3.0, and bats-assert v2.2.4. The individual installer
suite is also available as `just test-installer`. Both commands work without
Python or a virtual environment, never fetch dependencies, and forward Bats
options such as `just test --filter 'package mappings'`. Bash (including macOS
system Bash 3.2), Git, GNU Stow, `ps`/`pkill` for Bats timeouts, Zsh, Neovim
0.11.3+, and Just are required for the complete suite. Missing pinned submodules
produce an explicit initialization instruction.

Bats provides a 30-second per-test timeout by default. CI job timeouts bound the
full suite; no custom process supervisor or Python runner is needed. The test
suite covers:

- Installer safety, Stow preflight/unlink, profiles, and paths with spaces.
- Just argument forwarding and task contracts.
- Real Zsh startup with disposable homes, offline network stubs, XDG overrides,
  history, plugins, and local overrides.
- Real headless Neovim startup and Lua assertions for mappings, navigation,
  search fallbacks, clipboard detection, plugin locks, LSP configuration, TODOs,
  formatters, and opt-in AI configuration.
- Package manifest mappings, platform/release policy, dry-run safety, and doctor
  version checks using stubs that cannot modify the host.

Editor and shell fixtures use Bats temporary directories, private HOME/XDG/TMP
paths, and copies—not writable symlinks—of configuration. Inherited startup and
Git redirection variables are removed from child environments. Normal tests
never bootstrap plugins or download parsers. Interactive fzf, live language
servers, formatters, clipboard round trips, and AI/MCP services remain manual
checks. Isolation is not a security sandbox; run only trusted repository code.

## Checks and formatting

```sh
just check
just lint
just fmt-check
```

`just check` parses shell, JSON, and Python tooling sources without executing
configuration. Python is used by this syntax-check/tooling path and to install
checksum-pinned CI tools; **there are no Python test modules, Python test
frameworks, test requirements, or test virtual environment**. ShellCheck and
StyLua are standalone quality tools, not test dependencies.

## CI coverage

The workflow runs the complete Bats suite on Ubuntu and macOS, plus Debian 13
and Arch containers. Fedora is not a supported provisioning target. macOS runs the installer suite with
system Bash 3.2 and BSD utilities. Pinned vendor submodules are checked out
recursively. No Python packages or Python venv are installed. CI still installs
Python itself for the repository's checksum-verifying tool installer and syntax
checker. Neovim, Just, and StyLua releases are checksum-verified; third-party
Actions use immutable commit SHAs. Package-manager images and OS packages are
not frozen. The network-dependent plugin smoke is a separate opt-in job.

## Opt-in real plugin startup

Use **Actions → Validation → Run workflow → `plugin_startup`** or run explicitly:

```sh
sh .github/workflows/plugin-smoke.sh
```

This shell script copies the editor configuration into a disposable HOME, runs
the explicit locked `setup.lua` bootstrap, then checks real plugin startup and
each installed Git revision against `lazy-lock.json`. It intentionally requires
network access; the standard Bats suite never runs it. It does not validate every
mapping or external language tool.

## WSL manual smoke

Use real WSL2, not a Linux container as a substitute. Record Windows/WSL and
distro versions, architecture, terminal, and tool versions. Clone into the Linux
filesystem (not `/mnt/c`), initialize vendor submodules, and run `just check`,
`just lint`, `just fmt-check`, and `just test`. In a disposable user, install
twice and verify links, conflict protection, and unrelated files. Exercise
interactive Zsh, Neovim explorer/search/pickers, and terminal clipboard behavior.
Record optional plugin/network/service checks separately; these host-dependent
flows are not fully automated.

# Testing

## Local, plugin-free validation

Requirements: Python 3.10+, Neovim **0.11.3+**, Git, GNU Stow, zsh, and
[just](https://github.com/casey/just). Install ripgrep and fzf for realistic manual
editor checks. CI pins Neovim 0.11.5 and just 1.43.1 and verifies their release
archives against committed SHA-256 digests.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-test.txt
.venv/bin/python -m pip check
just check
just lint
just test
```

The Python runtime dependencies (including transitives) are pinned in
`requirements-test.txt`; update them deliberately and run the full matrix. Native
CI uses Python 3.12.10; distro jobs also exercise their packaged Python versions.
OS packages and the Arch rolling image are intentionally not frozen.

`just check` and `just test` are the public validation entry points. Do not
silence baseline failures with skips. The bounded runner `sh scripts/test.sh`
checks versions and kills the suite process group on timeout (60 seconds for
unit tests, 300 seconds for Behave). The Just recipe delegates to this runner.
It accepts Behave arguments, for example:

```sh
sh scripts/test.sh features/01_boot_and_shared_config.feature
```

Dependency-free tests of the isolation hooks can run independently:

```sh
python3 -B -m unittest discover -s test -p test_environment.py -v
```

Every Behave scenario gets a temporary HOME, private XDG config/data/state/cache/
runtime and search directories, and a private TMPDIR. Host shell/editor startup
overrides (including ZDOTDIR, VIMINIT, and NVIM_APPNAME) are removed. Child-specific
homes inherit this isolation. Editor configuration is copied, not symlinked into
a writable checkout. Git global/system configuration is excluded. Cleanup closes
the embedded editor transport, removes temporary directories even on failures,
and restores the parent environment. Hooks also register a Behave cleanup fallback.
On pinned pynvim, cleanup also reaps its child with a two-second deadline (closing
the transport alone can leave a zombie on newer Python). The suite runs scenarios
serially because it temporarily changes `os.environ`.

Normal tests disable plugin bootstrap and use test doubles for plugin behavior;
they do **not** need plugin network access. Provisioning Python/OS tools and
checking out submodules still requires network. Environment isolation is not a
security sandbox: run only trusted repository code. Do not run tests as root on
your workstation, or use your real HOME for install tests.

## CI coverage

`.github/workflows/validation.yml` runs the complete check/test contract on
Ubuntu and macOS, plus real Debian 13, Fedora 43, and Arch containers. Each
container installs its own zsh, Stow, Git, Python, ripgrep, and fzf and executes
the suite, rather than accepting a missing-tool skip. Third-party actions are
pinned to verified commit SHAs. Release downloads use pinned versions and
SHA-256 hashes recorded from GitHub's release-asset metadata. Failed checksum
validation is fatal. Job deadlines provide an outer bound as well.

## Opt-in plugin startup integration

Use **Actions → Validation → Run workflow → plugin_startup** to enable the
separate network integration job. Or, with Neovim 0.11.3+ and Git installed:

```sh
python3 -B .github/workflows/plugin-smoke.py
```

This uses a disposable HOME/config copy, runs the explicit locked `setup.lua`
entry point, and checks a second startup for errors, installed plugin
directories, lazy.nvim, and fzf-lua. Plugin downloads are intentionally real and
use the reviewed plugin lock; this is not a test of every plugin mapping or of
external language-server/formatter versions. Network/bootstrap failure fails the job.
Each editor invocation has a deadline. The normal PR matrix never runs this job.

## WSL manual smoke (not container-emulated)

Use an actual Windows host with WSL2 and an installed Ubuntu or Debian distro.
Record Windows/WSL versions (`wsl --version` in PowerShell), distro release,
`uname -a`, terminal, `nvim --version`, Python, zsh, and Stow versions.

1. Clone into the Linux filesystem (for example `~/src/dotfiles`, not `/mnt/c`).
   Install the requirements above, create `.venv`, then run `just check` and
   `just test`. Record the results; do not treat a Linux CI container as WSL proof.
2. In a disposable WSL user, run the documented install entry point twice and
   verify symlinks and that a pre-existing unrelated file survives. Never test
   destructive conflicts against your primary account.
3. Start an interactive zsh in Windows Terminal; verify prompt, syntax
   highlighting, a new login shell, and a fresh tab. Check shell startup output
   for errors. Explicitly record which optional tools are installed.
4. Open Neovim in `test/fixtures/workspace`; exercise netrw open/close, command
   palette, file picker, and ripgrep search. If enabling plugins, run the opt-in
   smoke separately and record network access/results.
5. Check terminal clipboard behavior and Windows/Linux path boundaries manually;
   those are host-dependent and not guaranteed by the automated suite.

# Dependency provisioning

Configuration installation and dependency provisioning are separate. Nothing here
changes `install.sh` or config profile selection; see [profiles](profiles.md).
Provisioning `personal` is optional; Copilot apps/extensions are never part of dev.

```sh
bash scripts/packages.sh                         # dev, preview only
bash scripts/packages.sh --profile minimal       # preview shell/git/editor baseline
bash scripts/packages.sh --profile dev --install # explicit system changes/network
bash scripts/packages.sh --doctor                # check commands and Neovim version
bash scripts/packages.sh --profile dev --list    # native package names, one per line
```

Only `--install` runs package managers, network operations, or sudo. Preview is
the default and does not even require a package manager to be installed. Arguments
are passed as arrays, never evaluated as shell code. Root runs directly; non-root
Linux installs use sudo. macOS never uses sudo for Homebrew. Bootstrap Homebrew
yourself using its reviewed official instructions; this script never bootstraps a
manager, adds repositories, or pipes a downloaded installer into a shell.

## Source of truth and profiles

`packages/cli.tsv` is the canonical whitespace-delimited CLI mapping. Columns are
group, command, apt, pacman, brew; `-` means not provided by that manager.
The `base` group contains Git, Stow, Zsh, Vim and Python. `development` adds
Neovim, fzf, fd, ripgrep, gh, nano, just, Python packaging support and
download/archive tools. Profiles select these groups in `profiles/NAME.profile`.
Starship is optional: installed from Arch/Homebrew packages where mapped, not from apt.
On Debian/Ubuntu the fd executable is `fdfind`; the doctor accepts either name.

`Brewfile` reads the CLI mapping directly. `Aptfile` is a compatibility snapshot
of the default profile's apt selection, checked against the mapping by the test suite;
update it when changing the mapping, or regenerate it with:

```sh
bash scripts/packages.sh --manager apt --list > Aptfile
```

The manager override is for previews/listing only, still requires a supported host,
and is rejected with `--install`. The Dockerfile consumes the same mapping/script,
not a third package list. Its base is pinned to Debian 13 rather than moving
`debian`; this is a release pin, **not** an immutable image digest.

Profiles declare macOS bundles by name. On macOS, desktop selects
`packages/Brewfile.desktop`; personal selects both that and
`packages/Brewfile.personal` (including App Store purchases, VPN, Dropbox and
optional Copilot). All casks,
VS Code extensions and `mas` are guarded for macOS; `mas` is not a Linux formula.
App Store installs may require an interactive signed-in account and licenses.
On Linux, selected profiles provision CLI groups only and report application
bundles as macOS-only. To apply just one app bundle directly, use
`brew bundle --file=...`.

The stale `Brewfile.lock.json` has been deliberately retired. Homebrew Bundle
records/resolves current package availability; it is not an immutable lock to
historical formula, bottle or application versions. These manifests describe
intent, not bit-for-bit reproducibility. Do not restore the old lock as a pinning
mechanism. Exact builds require independently pinned artifacts/checksums or image
digests, which are outside this provisioning workflow.

## Platforms and capabilities

* Debian 13: apt; Ubuntu 24.04 and newer: apt.
* Arch Linux: pacman rolling, full `-Syu` upgrade to avoid partial upgrades.
* macOS: preinstalled Homebrew, Intel or Apple Silicon; Homebrew's own supported
  OS/bottle requirements still apply.
* Linux architectures: x86_64 and aarch64/arm64. Others fail before provisioning.
  Distro repositories remain authoritative for architecture-specific availability.

Linux uses `/etc/os-release` ID/VERSION_ID, not kernel branding or ID_LIKE guesses.
Unknown distributions/releases/architectures fail closed, even for previews.
Metadata is parsed, never sourced. WSL uses its actual Linux distribution and
these same rules. Windows executable/clipboard/browser interop is optional and
not installed or assumed; no Windows package manager is invoked.

## System versus user tools

Installer testing uses pinned Git submodules under `vendor/`: Bats v1.14.0,
bats-support v0.3.0, and bats-assert v2.2.4. It requires Bash (including macOS's
system Bash 3.2), Git, GNU Stow, and standard Unix tools. Bats per-test
timeouts need `ps` or `pkill`: dev provisioning includes `procps` on Debian/Ubuntu
and `procps-ng` on Arch; macOS supplies these tools with the system.
Native Bats/helper
packages are deliberately not provisioned or used. Prepare the test submodules
explicitly with `git submodule update --init --recursive -- vendor`; executing
tests never downloads dependencies. These are not application-install prerequisites.

Native managers own shared CLI dependencies. Antidote has exactly one source:
the pinned `zsh/.antidote` Git submodule, initialized by the existing submodule
workflow (`git submodule update --init --recursive` when explicitly requested).
There is no competing brew formula or container-time clone. Configuration
installation links that submodule through the zsh Stow package.

Python project dependencies belong in `.venv`, never sudo pip. Missing optional
Starship on apt should not block basic shells. If desired, choose a specific
official Starship release for your OS/architecture, download it and its published
checksum separately, verify with `sha256sum -c` (macOS: `shasum -a 256`), inspect
the archive, then install the binary under `~/.local/bin`. Alternatively use a
user-level version manager with a pinned version and verified artifacts. No
unverified `curl | sh` fallback is run automatically.

**Neovim must be >=0.11.3 for the configured plugin workflow.** Successfully
installing a distro package does not prove that requirement: Debian 13 and
Ubuntu 24.04 may supply older versions. `--doctor` exits nonzero for old/unknown
versions or missing required commands. Install an explicit official Neovim >=0.11.3
release matching your architecture into a versioned directory under `~/.local/opt`,
verify its published SHA256 before extracting, and link its `bin/nvim` into
`~/.local/bin` (already on the Zsh PATH). Alternatively use an explicitly configured
user-level version manager that verifies downloads. Run `command -v nvim`,
`nvim --version`, then `--doctor` to ensure PATH selects the intended binary.
The script neither replaces system binaries nor claims distro Neovim is new enough.

## Offline tests

```sh
just test --filter 'manager mappings'
```

Tests use temporary os-release fixtures, executable stubs and the preview-only
manager seam. `PACKAGES_TESTING=1` enables `PACKAGES_TEST_OS`,
`PACKAGES_TEST_ARCH`, and `PACKAGES_TEST_OS_RELEASE`; install is forbidden with
that flag. No host packages, sudo, or network calls are needed.

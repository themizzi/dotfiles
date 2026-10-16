# Safe installer

Run `sh /path/to/dotfiles/install.sh` from any directory, including paths with
spaces. The target is the existing absolute directory in `HOME`. GNU Stow is
required; linking also requires Git and initialized recursive submodules.

```sh
sh /path/to/dotfiles/install.sh --help
sh /path/to/dotfiles/install.sh --dry-run
sh /path/to/dotfiles/install.sh
sh /path/to/dotfiles/install.sh --unlink --dry-run
sh /path/to/dotfiles/install.sh --unlink
```

The default selection is `gh gh-copilot nano nvim starship vim zsh`. There are
currently no package-selection or profile arguments. Options may be combined in
either order. Both linking and unlinking simulate the entire selection before
applying it. Repeated runs are safe; linking uses `--stow`, not `--restow`.
Unlinking removes only links Stow recognizes as belonging to these packages;
it does not delete regular configuration files and does not require initialized
submodules. Stow may remove empty directories it managed.

## Prerequisites and offline operation

The installer never installs tools, initializes submodules, or accesses the
network. In a fresh checkout, prepare dependencies explicitly before linking:

```sh
git -C /path/to/dotfiles submodule update --init --recursive
```

This preparation may need network access. Once prerequisites are present, the
installer works offline. Missing submodules cause even `--dry-run` to fail
without changes. Application startup may separately download plugins; the
installer does not run those applications or their plugin managers.

## Conflicts and existing configurations

Existing files and foreign symlinks are not adopted or overwritten. A failed
preflight makes no changes. Inspect the exact paths Stow reports, save any
local edits, and explicitly move only the conflicting files to a backup
location you choose. Retry `--dry-run` before installing. Do not delete entire
`~/.config`, editor directories, or unrelated configuration to resolve a conflict.

For safety the installer refuses a `.stowrc` in HOME or the repository: ambient
Stow options can enable adoption or overriding. Review and temporarily move
that particular options file if needed. `.stowrc-gh` is a managed config file,
not Stow's options file, and is unaffected by this restriction.

For retired packages or stale links from an older checkout, inspect each link
with `ls -l` and `readlink`. If the old checkout still exists, prefer its
package-specific Stow delete operation after simulation. Otherwise remove only
an individually verified obsolete symlink (not its target), preserving regular
files and unrelated links. This installer deliberately does not sweep retired
packages or repair foreign links automatically.

Preflight is not a filesystem lock: avoid concurrent installers or edits to the
target while applying changes. A runtime failure is not a transactional rollback.

Devcontainer setup likewise preserves HOME configs. An existing malformed
`.venv` causes an explicit error rather than automatic deletion; inspect and
move it aside yourself before recreating it.

## Tests

```sh
git submodule update --init --recursive -- vendor # explicit setup, may use network
sh scripts/test-installer.sh
```

Tests use isolated temporary homes, shell stubs, and real GNU Stow. Bash, Git,
Stow, and standard Unix utilities are required; Python and a venv are not.
The wrapper always uses pinned Bats v1.14.0, bats-support v0.3.0, and bats-assert
v2.2.4 under `vendor/`, ignoring any system Bats installation. Submodules record
immutable release commits. Missing helpers fail clearly; tests never fetch them.
The installer checks only application submodules, so missing test dependencies
cannot block linking or unlinking dotfiles. Pass Bats options through the wrapper,
for example `sh scripts/test-installer.sh --filter 'real Stow'`.

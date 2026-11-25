# dotfiles

Portable Zsh, Vim, and Neovim configuration. The full Neovim setup requires
Neovim >= 0.12; without plugins, built-in navigation and search fallbacks
remain available.

## Install

Requires Git and GNU Stow. Install [Just](https://just.systems/) 1.31.0 or newer
(`brew install just` on macOS) or use `sh install.sh` directly.

```sh
git submodule update --init --recursive   # required once before linking
just install --dry-run                    # preview
just install
```

The installer links the selected profile into `$HOME` with Stow. It never
adopts or overwrites existing files; on a conflict, move only the reported
paths and retry. `just install --profile NAME` selects a profile.
`just install --unlink` removes only managed links; unlink the old profile
before switching to another.

Available profiles: `minimal` (vim, zsh) and `personal` (default: gh,
gh-copilot, nano, nvim, starship, vim, zsh).

## Install CLI dependencies

```sh
bash scripts/packages.sh                        # preview the default profile
bash scripts/packages.sh --profile minimal      # preview a profile
bash scripts/packages.sh --install              # install (needs network/sudo)
bash scripts/packages.sh --doctor               # check required commands
bash scripts/packages.sh --list                 # print package names
```

Supported: Debian 13, Ubuntu 24.04+, Arch (x86_64/arm64), and macOS with
preinstalled Homebrew. The `personal` profile also installs the macOS
application bundles from `packages/Brewfile.*`. The script never bootstraps a
package manager. If your distro Neovim is older than 0.12, install an
official release under `~/.local/opt` and link `bin/nvim` into
`~/.local/bin`, then re-run `--doctor`.

## Neovim

Normal startup never downloads plugins. To install the reviewed plugin set
after linking (needs Neovim >= 0.12, Git, and network):

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

Language servers and formatters are never installed automatically; use
`:Mason` or your package manager, then restart Neovim. Use `"+y` / `"+p` for
the system clipboard. See [nvim/.config/nvim/USAGE.md](nvim/.config/nvim/USAGE.md)
for all mappings.

## Zsh

Plugin bundles load automatically on first interactive start after
initializing the submodule. Put private settings in `~/.zshrc.local`
(mode 600, not committed). History and plugin caches live under the XDG
directories; history is stored in `$XDG_STATE_HOME/zsh/history`.

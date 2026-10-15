# dotfiles

Portable Zsh, Vim, and Neovim configuration with explicit, offline-safe startup.
The full Neovim layer requires version 0.11.3 or newer; plugin-free startup
retains useful built-in navigation and search. See [Neovim setup](docs/neovim.md)
for the reviewed plugin versions and supported Treesitter runtime.

## Install

From repo root:

```bash
just install
```

`install.sh` uses GNU Stow with `--target="$HOME"` and creates symlinks such as:

- `~/.vimrc` -> `vim/.vimrc`
- `~/.config/nvim/init.vim` -> `nvim/.config/nvim/init.vim`

The script is idempotent and preflights the entire selection before linking.
Use `just install --dry-run` to preview changes or `just install --unlink` to
remove managed links. Existing configuration is never adopted or overwritten.
See [installer safety](docs/installer.md) and [Just tasks](docs/just.md).

The default `dev` profile selects general development configuration. Choose
`just install --profile minimal` for Vim/Zsh, or `--profile personal` to include
optional Copilot preferences. See [profile selection](docs/profiles.md) for exact
package lists and safe switching/unlinking.

Install the Just command runner with `brew install just` on macOS or
`sudo apt-get install just` on Debian releases that package it. Direct
`sh install.sh` remains supported without Just. See [Just tasks](docs/just.md)
for argument forwarding, prerequisites, and offline checks.

## Devcontainer (Debian)

Open this repository in a devcontainer with VS Code (`Dev Containers: Reopen in Container`).

On first create, `.devcontainer/scripts/post-create.sh` runs and:

- initializes/updates git submodules
- initializes repository submodules without installing Python test dependencies

No third-party Python test packages are needed.

The Debian 13 image consumes the same [CLI package mapping](packages/cli.tsv)
as the native provisioning adapters; there is no separate container package list.
System provisioning is separate from linking configuration:

```bash
bash scripts/packages.sh --profile dev --dry-run
bash scripts/packages.sh --profile dev --install # explicit system changes
bash scripts/packages.sh --profile dev --doctor
```

Supported adapters cover Debian/Ubuntu, Fedora, Arch, and macOS Homebrew.
WSL uses its Linux distribution's adapter. See [dependency policy](docs/dependencies.md)
for supported releases, optional Starship, and verified user-level tool installation.
Check Neovim's version explicitly: a successfully installed distro package may
still be older than the full configuration requires.

The default `dev` profile excludes personal Copilot preferences. Use
`just install --profile minimal` for Vim/Zsh or `--profile personal` to opt in
to the former complete selection. See [configuration profiles](docs/profiles.md).
Desktop and personal macOS applications are separate, explicit Homebrew bundles.

Verify inside the container:

```bash
just install
just check
just test
```

## Usage

- `<leader>` is space.
- `<leader>e` toggles nvim-tree, or netrw without plugins; `<leader>fe` reveals the current file.
- `<leader>ff`, `fb`, `fc`, `fg`, `fh`: files, buffers, commands, workspace search, and help.
- `<leader>tn`, `tp`, `tl`, `tq`, `tf`, `ts`: TODO navigation, lists, and search.
- `s` / `S`: Flash navigation with plugins; coverage and Diffview commands remain available.
- Native clipboard detection works without overriding system providers.

Normal startup never installs plugins. Enable the reviewed plugin layer explicitly
after linking configuration:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

Without plugins, file/search/explorer mappings use built-in fallbacks.
CodeCompanion is opt-in through `DOTFILES_NVIM_AI=1`, with a configurable endpoint
and model. Parser installation, language servers, formatters, image tools, and MCP
services are explicit choices. See [Neovim documentation](docs/neovim.md) and
[portable shell setup](docs/zsh.md) for setup commands and prerequisites.

## Tests

Installer safety and real-Stow tests use the pinned Bats runner and helpers:

```sh
git submodule update --init --recursive -- vendor
sh scripts/test-installer.sh
```

This suite needs Bash, Git, and Stow, but no Python or system Bats installation.
See [installer tests](docs/installer.md).

Run the full suite:

```bash
just test
```

Run syntax checks without installing dependencies or executing configuration:

```bash
just check
```

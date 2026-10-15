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

Install the Just command runner with `brew install just` on macOS or
`sudo apt-get install just` on Debian releases that package it. Direct
`sh install.sh` remains supported without Just. See [Just tasks](docs/just.md)
for argument forwarding, prerequisites, and offline checks.

## Devcontainer (Debian)

Open this repository in a devcontainer with VS Code (`Dev Containers: Reopen in Container`).

On first create, `.devcontainer/scripts/post-create.sh` runs and:

- initializes/updates git submodules
- initializes repository submodules without installing Python test dependencies

Required Debian packages for Neovim + command palette workflow:

- `neovim`
- `fzf`
- `fd-find`
- `ripgrep`
- `python3`
- `python3-pip`
- `python3-venv`
- `curl`
- `ca-certificates`
- `git`
- `just`
- `stow`
- `unzip`
- `wget`
- `zsh`

No Python environment or third-party test packages are needed for installer tests.

On macOS, ensure these Homebrew entries exist in `Brewfile`:

- `brew "neovim"`
- `brew "fzf"`
- `brew "fd"`
- `brew "ripgrep"`
- `brew "just"`

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

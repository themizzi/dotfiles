# dotfiles

Minimal Vim-first dotfiles with a Neovim shim, built-in `netrw`, and an `fzf-lua` command palette on Neovim.

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
- `<leader>e` toggles built-in netrw via `:Lexplore`.
- `<leader>p` opens `fzf-lua` files picker.
- `<leader>b` opens `fzf-lua` buffers picker.
- `<leader>c` opens `fzf-lua` commands picker.
- `<leader>g` opens `fzf-lua` live grep when `rg` is available; otherwise falls back to a safe built-in search.
- `<leader>h` opens `fzf-lua` help tags picker.

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

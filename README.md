# dotfiles

Minimal Vim-first dotfiles with a Neovim shim, built-in `netrw`, and an `fzf-lua` command palette on Neovim.

## Install

From repo root:

```bash
sh install.sh
```

`install.sh` uses GNU Stow with `--target="$HOME"` and creates symlinks such as:

- `~/.vimrc` -> `vim/.vimrc`
- `~/.config/nvim/init.vim` -> `nvim/.config/nvim/init.vim`

The script is idempotent (`stow --restow`).

## Devcontainer (Debian)

Open this repository in a devcontainer with VS Code (`Dev Containers: Reopen in Container`).

On first create, `.devcontainer/scripts/post-create.sh` runs and:

- initializes/updates git submodules
- creates `.venv` if it does not already exist
- prepares a standard-library Python test environment without downloading packages

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
- `stow`
- `unzip`
- `wget`
- `zsh`

No third-party Python test packages are needed.

On macOS, ensure these Homebrew entries exist in `Brewfile`:

- `brew "neovim"`
- `brew "fzf"`
- `brew "fd"`
- `brew "ripgrep"`

Verify inside the container:

```bash
sh install.sh
sh scripts/test-installer.sh
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
See [installer tests](docs/installer.md). Other suites remain Python-based.

Run any additional standalone Python tests using the standard library:

```bash
python3 -m venv .venv
.venv/bin/python -B -m unittest discover -s test -p 'test_*.py'
```

No feature files, step definitions, embedded RPC client, or third-party Python
test framework are required. Installer checks use Bats; shell/editor checks use
standalone tests with isolated temporary environments.

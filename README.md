# dotfiles

Minimal Vim-first dotfiles with a Neovim shim and built-in `netrw` only.

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
- installs `behave` and `pynvim` into `.venv`

Verify inside the container:

```bash
sh install.sh
.venv/bin/behave
```

## Usage

- `<leader>` is space.
- `<leader>e` toggles built-in netrw via `:Lexplore`.

## Tests (BDD / Neovim UI protocol)

Tests use Behave + `pynvim` with Neovim `--embed`, `nvim_ui_attach`, and redraw/grid events.

Install test dependencies in a local venv:

```bash
python3 -m venv .venv
.venv/bin/pip install behave pynvim
```

Run the suite:

```bash
.venv/bin/behave
```

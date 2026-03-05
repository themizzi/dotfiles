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
- installs `behave` and `pynvim` into `.venv`

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
- `zellij`
- `zsh`

`post-create.sh` installs Python test dependencies with:

```bash
.venv/bin/python -m pip install behave pynvim
```

On macOS, ensure these Homebrew entries exist in `Brewfile`:

- `brew "neovim"`
- `brew "fzf"`
- `brew "fd"`
- `brew "ripgrep"`
- `brew "zellij"`

## Terminal multiplexer (phase 1)

Zellij is the preferred terminal multiplexer in this repo.

Install and link dotfiles:

```bash
sh install.sh
zj
```

Minimal zellij workflow in this setup:

- `Alt+n`: new pane
- `Alt+v`: vertical split (new pane to the right)
- `Alt+h`: horizontal split (new pane below)
- `Alt+Arrow`: move focus between panes
- `Alt+s`: open session mode workflow

### Zellij command palette (action builder)

Trigger: `Alt+Space`

Requires `fzf` and `zellij`.

This palette is action-only (no project commands) and fully auto-discovers actions from
`zellij action --help` as `Action: <subcommand>`.

For a selected action, the palette opens an iterative builder loop:

- `Add option`
- `Add argument`
- `Review command`
- `Run command`
- `Cancel`

Builder behavior:

- Options are discovered from `zellij action <subcommand> --help`
- Supports flag options, valued options, and enum-valued options
- Supports multiple options and multiple positional arguments
- Duplicate non-repeatable options are blocked with `Replace existing option` / `Keep existing option`
- Repeatable options are inferred conservatively from help text; unclear cases default to non-repeatable
- Required positional arguments must be present before execution
- Final render order is options first, then positional arguments

Shortcut hints are display-only and inferred from zellij keybind config when available.
Hints appear on the right side and never change the action selection identity.
Mode-required shortcuts are shown as key chains, for example `Ctrl t > down`.

Non-interactive environment variables:

- `DOTFILES_ZELLIJ_PALETTE_CHOICE`
- `DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE`
- `DOTFILES_ZELLIJ_PALETTE_INPUT_SEQUENCE`
- `DOTFILES_ZELLIJ_PALETTE_DRY_RUN`
- `DOTFILES_ZELLIJ_PALETTE_LIST_ONLY`
- `DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH` (optional deterministic width for right-side hint rendering)

For deterministic loop tests, provide newline-delimited choices in
`DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE` and newline-delimited free-text inputs in
`DOTFILES_ZELLIJ_PALETTE_INPUT_SEQUENCE`.

`tmux` dotfiles and alias are still retained for compatibility during migration.

Verify inside the container:

```bash
sh install.sh
.venv/bin/behave
```

## Usage

- `<leader>` is space.
- `<leader>e` toggles built-in netrw via `:Lexplore`.
- `<leader>p` opens `fzf-lua` files picker.
- `<leader>b` opens `fzf-lua` buffers picker.
- `<leader>c` opens `fzf-lua` commands picker.
- `<leader>g` opens `fzf-lua` live grep when `rg` is available; otherwise falls back to a safe built-in search.
- `<leader>h` opens `fzf-lua` help tags picker.

## Tests (BDD / Neovim UI protocol)

Tests use Behave + `pynvim` with Neovim `--embed`, `nvim_ui_attach`, and redraw/grid events.

Install test dependencies in a local venv:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install behave pynvim
```

Stage-gated Neovim-only test commands:

```bash
nvim --headless +qall
.venv/bin/behave features/01_boot_and_shared_config.feature
.venv/bin/behave features/02_netrw_toggle.feature
.venv/bin/behave features/03_netrw_open_file.feature
.venv/bin/behave features/04_dotfiles_install_symlinks.feature
.venv/bin/behave features/05_fzf_lua_command_palette.feature
.venv/bin/behave features/06_fzf_lua_grep_workflow.feature
```

Run the full suite:

```bash
.venv/bin/behave
```

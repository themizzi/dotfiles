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

The Linux packages also include Hyprland, Hyprshell, the Hypridle user unit,
and the active Toshy config. On a Hyprland system, reload the user units after
installing and enable Hypridle for the graphical session:

```bash
systemctl --user daemon-reload
systemctl --user enable hypridle.service
```

`Pacmanfile` lists the Arch packages used by this setup. Toshy's installed
application and runtime state are not managed here; only `toshy_config.py`
and `KEYBOARD.md` are Stowed. Review the active Toshy config against Toshy's
upstream defaults when upgrading Toshy.

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

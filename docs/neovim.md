# Neovim

The full configuration requires **Neovim 0.11.3 or newer** (tested on 0.11.3 and 0.11.6).
Vim and older Neovim retain the shared `~/.vimrc` defaults. Install the `nvim`
and `vim` Stow packages; Neovim can also run independently of `~/.vimrc`.

## Offline first

Normal startup never clones repositories, installs missing plugins, checks for
updates, downloads parsers, or installs language servers. With no plugins, all
leader mappings below work through built-ins. Set
`DOTFILES_SKIP_PLUGIN_BOOTSTRAP=1` to force this mode even with plugins installed.
Built-in file/search fallbacks skip hidden directories and files larger than 1 MiB
(search only); they are intended for modest workspaces, not huge monorepos.

Leader is **Space**:

| Mapping | Plugin layer | Offline baseline |
| --- | --- | --- |
| `<leader>e` | nvim-tree toggle | netrw `:Lexplore` toggle |
| `<leader>ff` | fzf files | built-in file selection |
| `<leader>fb` | fzf buffers | built-in buffer selection |
| `<leader>fc` | fzf commands | command selection, then edit arguments/Enter |
| `<leader>fg` | live grep (requires `rg`) | prompt for Vim regex, results in quickfix |
| `<leader>fh` | fzf help | built-in help-tag selection |
| `<leader>m` | Conform format | attached LSP format |
| `<leader>/` | native comment toggle | native comment toggle |
| `<leader>?` | which-key | list leader mappings |
| `<leader>r` | registers | registers |

Built-in pickers use `vim.ui.select`: enter the displayed item number and press
Enter. Search accepts Vim regex, not ripgrep syntax; cancel/empty input does
nothing. `:cnext`/`:cprev` navigate results. Native LSP offers `K`, `grn`, `gra`,
`grr`, `gri`, `gO`, and insert-mode completion; see `:help lsp-defaults`.
Surround and Git hunk actions are available only with their plugins installed
(`]h`, `[h`, `<leader>gh/gs/gr/gS/gR/gb`). Syntax highlighting uses Vim runtime
syntax, not automatically downloaded Treesitter parsers. The retired AI,
coverage, comment, and completion plugin stacks are intentionally removed.

## Explicit plugin setup

Prerequisites: Git, network access to GitHub, and Neovim >= 0.11.3. Install `fzf > 0.36`
for fuzzy pickers and `ripgrep` for live grep; missing tools use built-in fallbacks.
Icons are optional; install a Nerd Font if you want the devicon glyphs displayed.
Run **after** the config is linked, with the skip variable unset:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

This is the only bootstrap entry point. It checks out lazy.nvim at immutable
commit `6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a` (v11.17.1), then performs one
synchronous locked install/restore, installing missing plugins. It is safe to rerun.
`lazy-lock.json` contains real upstream-resolved revisions; specs also pin those
commits, so updating requires deliberately reviewing/editing the lock and rerunning
setup. Lazy's writable working lock lives under its data directory; it never
rewrites the tracked source lock. LSP configuration is pinned to nvim-lspconfig v2.5.0 and Mason/mason-lspconfig
v2.1.0, using the Neovim 0.11 `vim.lsp.config`/`enable` APIs, not removed handlers.
Do not use `:Lazy sync` as an unattended installer or update mechanism.

### Language tools: explicitly installed, never automatic

Mason initializes its PATH before LSP executable detection. Missing optional
servers produce a warning, not an implicit install. Install only what you use,
via `:Mason` or your system package manager; restart Neovim afterward:

Mason-lspconfig v2 refreshes its registry on setup, so it loads only on explicit
`:LspInstall`/`:LspUninstall`. `:Mason` and those commands may access the network;
ordinary startup does not refresh the registry.

| LSP | Executable / prerequisite |
| --- | --- |
| Lua | `lua-language-server` |
| Python | `pyright-langserver` (`pyright`; Node.js) |
| JavaScript/TypeScript | `typescript-language-server`, `typescript` (Node.js) |
| Go | `gopls` (Go) |
| Rust | `rust-analyzer` (Rust toolchain) |
| Shell | `bash-language-server` (Node.js) |

Conform uses the first available formatter in each fallback list, **not all of
them in sequence**: JS/TS/JSON/YAML `prettierd` then `prettier` (Node.js); Python
`ruff` then `black`; Lua `stylua`; shell `shfmt`; Go `gofmt`; Rust `rustfmt`.
Install these yourself through Mason/system/language package managers. Format on
save waits up to 500 ms and falls back to an attached LSP when no formatter is
available. `:ConformInfo`, `:Mason`, `:checkhealth vim.lsp`, and `:messages` diagnose
tool availability. Additional servers can be enabled explicitly in `plugins/lsp.lua`.

## Clipboard

Neovim auto-detects the native system provider (`wl-copy`/`wl-paste`, `xclip`,
`pbcopy`, etc.), with its built-in OSC52 provider as fallback when the terminal
advertises support. Use `"+y` / `"+p` to access it. We do not force `unnamedplus`:
Neovim 0.11 disables automatic OSC52 selection when that option is set, and
automatic clipboard reads can be slow. No fake paste implementation replaces
the system clipboard.
Remote OSC52 depends on terminal/multiplexer support and permissions; reading
the clipboard may be unsupported or require confirmation. Use terminal paste
when OSC52 reads are unavailable. See `:checkhealth vim.provider`.
If terminal detection fails, explicitly opt in with `:let g:clipboard = 'osc52'`
before first clipboard use (or in your local init). Local users who prefer every
yank to use their system clipboard can explicitly `:set clipboard=unnamedplus`.

## Optional AI (no plugin dependencies)

AI is disabled unless `DOTFILES_NVIM_AI=1`. To opt in, set
`DOTFILES_NVIM_AI_ENDPOINT` to the **complete** OpenAI-compatible chat-completions
URL (for example `http://127.0.0.1:1234/v1/chat/completions`) and
`DOTFILES_NVIM_AI_MODEL` to a model your server exposes. Optional
`DOTFILES_NVIM_AI_API_KEY` supplies a bearer token. Requires `curl`.

`:DotfilesAI explain a Lua closure` sends **only that explicitly entered prompt**
and shows the answer in a scratch buffer. It never sends buffers automatically,
invokes tools, or changes files. Requests time out after 120 seconds. Remote
endpoints receive your prompts; prefer HTTPS unless using a trusted local server.
No AI service is contacted at startup and the command does not exist when disabled.

## Tests

```sh
python3 -m unittest discover -s test -p test_neovim.py -v
behave features/01_boot_and_shared_config.feature features/02_netrw_toggle.feature \
  features/03_netrw_open_file.feature features/05_fzf_lua_command_palette.feature \
  features/06_fzf_lua_grep_workflow.feature
```

Headless tests use fresh HOME/XDG directories, disable plugins, and never download
anything. They skip if Neovim >= 0.11.3 is unavailable. Behave additionally needs
`behave` and `pynvim`; its fzf scenarios capture dispatch, not a real interactive
fzf terminal session. Explicit plugin restore and a real plugin-loaded headless
startup should also be checked when updating the lock.

Validated for this revision on Linux: eight isolated headless tests and
plugin-loaded smoke startup on both Neovim 0.11.3 and 0.11.6; on 0.11.6,
nine embedded Behave scenarios (44 steps), fresh and repeated explicit
plugin setup, and all 13 repository HEADs matching the source lock.
Real fzf terminal interaction, language-server conversations,
formatter binaries, live AI endpoints, and terminal clipboard round trips were
not exercised; the AI request/response test stubs transport and the OSC52 test
checks native provider selection only.

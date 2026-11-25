# Neovim

The full configuration requires **Neovim >= 0.12**. Vim and older Neovim
retain the shared `~/.vimrc` defaults. Install the
`nvim` and `vim` Stow packages; Neovim also works independently of `~/.vimrc`.

## Usage

See the [usage guide](../nvim/.config/nvim/USAGE.md) for mappings and workflows.
The full setup uses Snacks, OpenCode, Catppuccin Mocha, lualine, Markdown
rendering, and the existing LSP, formatting, Git, and editing plugins.
Normal startup does not download plugins or tools. Without plugins, netrw and
built-in picker/search fallbacks remain available. Set
`DOTFILES_SKIP_PLUGIN_BOOTSTRAP=1` to force the baseline.

## Explicit locked plugin setup

Prerequisites: Git, network access to GitHub, and Neovim >= 0.12. Install
`ripgrep` for Snacks live search. A Nerd Font is recommended for icons.

After linking the config, run with the skip variable unset:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

The helper checks out lazy.nvim at immutable commit
`6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a` (v11.17.1), then synchronously
installs/restores reviewed revisions. It is safe to rerun and does not clean up
other plugin directories. Normal startup never installs missing plugins.

`lazy-lock.json` is the reviewed source of **real upstream commit hashes**.
Specs also pin those commits and branches; updating requires deliberately
reviewing/editing the lock and rerunning setup. Lazy's writable working lock is
under its data directory and never rewrites the tracked source. API choices:

- nvim-lspconfig v2.5.0 and Mason/mason-lspconfig v2.1.0 use Neovim's
  `vim.lsp.config` / `vim.lsp.enable`, not removed Mason handlers.
- Blink v1.9.1 uses its Lua fuzzy backend.
- Treesitter uses the **`main` API** pinned at
  `29212d826054bb2948fa9d3a99eca9bf6a050eb2` for Neovim 0.12.
  A FileType autocommand enables native highlighting and plugin indentation
  when a parser is available.
Do not use `:Lazy sync` as an unattended installer/update mechanism.

### Treesitter parsers: a separate explicit choice

There is **no build hook, automatic parser installation, or `ensure_installed`
list at startup**. Vim syntax remains the baseline before parsers are installed.
To install the original language set plus Markdown/inline Markdown/vimdoc:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP DOTFILES_NVIM_INSTALL_PARSERS=1 \
  nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

This explicitly runs Treesitter's `install(...):wait(...)` API against the pinned
revision and verifies the resulting parsers load. Requires a C/C++
compiler (`cc`/`gcc`/`clang`), libstdc++, `tar`, `curl` (or Git), and a compatible
`tree-sitter` CLI **0.26.1 or later** (`brew install tree-sitter-cli` on macOS).
No compiler/CLI is needed just to start
the baseline editor. Alternatively install only what you use with
`:TSInstall lua markdown markdown_inline yaml`. Markdown and inline Markdown parsers improve rendered Markdown. `:TSUpdate` is a manual network operation;
review parser compatibility whenever changing the plugin lock.

### Language servers and formatters: never implicitly installed

Mason initializes PATH **before** executable detection. The full original server
set is configured; only executables found on PATH are enabled. Missing optional
tools are silently skipped. Install what you use with `:Mason` or your
system/language package manager, then restart Neovim:

| LSP | Executable / prerequisite |
| --- | --- |
| Lua | `lua-language-server` |
| Python | `pyright-langserver` (`pyright`; Node.js) |
| JavaScript/TypeScript | `typescript-language-server` and TypeScript (Node.js) |
| Tailwind | `tailwindcss-language-server` (`@tailwindcss/language-server`; Node.js) |
| Go | `gopls` (Go) |
| Rust | `rust-analyzer` (Rust toolchain) |
| YAML | `yaml-language-server` (Node.js) |
| JSON / HTML / CSS | `vscode-json-language-server`, `vscode-html-language-server`, `vscode-css-language-server` (`vscode-langservers-extracted`; Node.js) |
| Astro | `astro-ls` (`@astrojs/language-server`; Node.js) |
| Emmet | `emmet-ls` (Node.js) |
| GraphQL | `graphql-lsp` (`graphql-language-service-cli`; Node.js) |
| Shell | `bash-language-server` (Node.js) |
| Docker | `docker-langserver` (`dockerfile-language-server-nodejs`; Node.js) |
| C/C++ | `clangd` (LLVM) |

Mason-lspconfig v2 refreshes its registry on setup, so it loads only on explicit
`:LspInstall` / `:LspUninstall`. Those commands and `:Mason` may use the network;
ordinary startup doesn't refresh the registry.

Conform chooses the **first available** formatter in each list, not accidental
chains: JS/TS `prettierd` then `prettier`; Python `ruff` then `black`; JSON `jq`
then the Prettier alternatives; YAML Mike Farah's `yq` then Prettier; Lua
`stylua`; shell `shfmt`; Go `gofmt`; Rust `rustfmt`. Install these explicitly.
Format-on-save waits up to 500 ms and falls back to an attached LSP when no
formatter is available. `:ConformInfo`, `:Mason`, `:checkhealth vim.lsp`, and
`:messages` diagnose availability.

## Clipboard

Neovim auto-detects native system providers (`wl-copy`/`wl-paste`, `xclip`,
`pbcopy`, etc.), then its built-in OSC52 provider when the terminal advertises
support. Use `"+y` / `"+p`. We don't force `unnamedplus`: Neovim 0.11 disables
automatic OSC52 selection when that option is set, and automatic reads can be
slow. No fake paste function substitutes local registers for the clipboard.

Remote OSC52 needs terminal/multiplexer support and permissions. Clipboard reads
may be unsupported or need confirmation; use terminal paste when unavailable.
See `:checkhealth vim.provider`. If detection fails, opt in explicitly with
`:let g:clipboard = 'osc52'` before first clipboard use (or in your local init).
Local users can explicitly `:set clipboard=unnamedplus` for all yanks.

## Tests

```sh
just test
```

The Bats suite exercises offline defaults, plugin specs, picker dispatch, TODO
mappings, and language-server configuration.

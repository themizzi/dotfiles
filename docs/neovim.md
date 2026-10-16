# Neovim

The full configuration requires **Neovim >= 0.11.3** (tested on 0.11.3 and
0.11.6). Vim and older Neovim retain the shared `~/.vimrc` defaults. Install the
`nvim` and `vim` Stow packages; Neovim also works independently of `~/.vimrc`.

## Offline first, without removing the full editor workflows

Normal startup never clones plugins, checks for updates, downloads completion
binaries/parsers, or installs language servers. With no plugins, netrw and useful
built-in pickers/search remain available. Set `DOTFILES_SKIP_PLUGIN_BOOTSTRAP=1`
to force this baseline even when plugins are installed.

The full layer retains TODO navigation/search, coverage, autopairs, Flash,
indent guides, Blink completion and friendly snippets, Treesitter highlighting
and indentation, all 16 original language servers, formatting, surround, Git
hunks/Diffview, nvim-tree, fzf-lua, which-key, and Tokyo Night. Native Neovim
commenting and clipboard providers replace only the redundant comment/OSC52
plugins. CodeCompanion and its optional companions are disabled by default.

Leader is **Space**:

| Mapping | Full plugin layer | Offline baseline |
| --- | --- | --- |
| `<leader>e` | nvim-tree toggle | netrw `:Lexplore` toggle |
| `<leader>fe` | reveal file in tree | netrw explorer |
| `<leader>ff` | fzf files | built-in file selection |
| `<leader>fb` | fzf buffers | built-in buffer selection |
| `<leader>fc` | fzf commands | command selection, then edit arguments/Enter |
| `<leader>fg` | live grep (requires `rg`) | Vim-regex prompt, results in quickfix |
| `<leader>fh` | fzf help | built-in help-tag selection |
| `<leader>tn` / `tp` | next / previous TODO | warns that plugin setup is needed |
| `<leader>tl` / `tq` / `tf` | TODO location list / quickfix / fzf | warns that plugin setup is needed |
| `<leader>ts` | search TODO/FIXME/HACK/NOTE | built-in regex search prompt |
| `<leader>m` | Conform format | attached LSP format |
| `<leader>/` | native comment toggle | native comment toggle |
| `<leader>?` | which-key | list leader mappings |
| `<leader>r` | registers | registers |

With plugins: `s` / `S` invoke Flash jump / Treesitter selection; surround uses
its standard mappings. Git actions retain `]h`, `[h`, and
`<leader>gh/gs/gr/gS/gR/gb`. Use `:DiffviewOpen`, `:DiffviewFileHistory`, and
`:DiffviewClose` for diffs. Coverage retains `:Coverage`, `:CoverageToggle`, and
`:CoverageSummary`, automatically loading `coverage/lcov.info` when present.
Generate reports with your language's test/coverage tools; the plugin doesn't
install those tools. Blink uses the **Lua fuzzy backend**, native snippet
expansion, and friendly-snippets, never downloaded Rust binaries.

Built-in pickers use `vim.ui.select`: enter an item number and press Enter.
Fallback search accepts **Vim regex**, not ripgrep syntax; empty/cancel does
nothing. `:cnext` / `:cprev` navigate results. These synchronous fallbacks skip
hidden files/directories and files larger than 1 MiB (search only), and suit
modest workspaces rather than huge monorepos. Native LSP mappings remain
available (`K`, `grn`, `gra`, `grr`, `gri`, `gO`); manually attached LSPs can use
native completion even in the plugin-free baseline.

## Explicit locked plugin setup

Prerequisites: Git, network access to GitHub, and Neovim >= 0.11.3. Install
`fzf > 0.36` for fuzzy pickers and `ripgrep` for live grep/TODO lists. Missing
picker tools use built-in fallbacks where listed above. Devicon glyphs need a
Nerd Font, but icons are optional.

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
- Treesitter is pinned to the **frozen `master` configs API** at
  `cf12346a3414fa1b06af75c79faebe7f76df080a`, not the incompatible moving `main`.
  Upstream supports Neovim 0.10/0.11 on this legacy branch and explicitly does
  not support 0.12; moving to Neovim 0.12 requires a reviewed Treesitter migration.
- CodeCompanion v17.33.0 deliberately retains the `strategies` API compatible
  with MCPHub v6.2.0. It supplies the existing chat/inline/cmd workflows rather
  than introducing another AI client. A v19 upgrade needs an MCP adapter review.

Do not use `:Lazy sync` as an unattended installer/update mechanism.

### Treesitter parsers: a separate explicit choice

There is **no build hook, automatic parser installation, or `ensure_installed`
list at startup**. Vim syntax remains the baseline before parsers are installed.
To install the original language set plus Markdown/inline Markdown/vimdoc:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP DOTFILES_NVIM_INSTALL_PARSERS=1 \
  nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

This explicitly runs `:TSInstallSync` against the pinned Treesitter revision's
own parser lock and verifies the resulting parsers load. Requires a C/C++
compiler (`cc`/`gcc`/`clang`), libstdc++, `tar`, `curl` (or Git), and a compatible
`tree-sitter` CLI **up to 0.25.x** (tested with 0.25.10). Do not blindly install
the latest CLI for this frozen plugin. No compiler/CLI is needed just to start
the baseline editor. Alternatively install only what you use with
`:TSInstall lua markdown markdown_inline yaml`. Markdown and YAML parsers are
required by CodeCompanion's chat UI. `:TSUpdate` is a manual network operation;
review parser compatibility whenever changing the plugin lock.

### Language servers and formatters: never implicitly installed

Mason initializes PATH **before** executable detection. The full original server
set is configured; only executables found on PATH are enabled, with one warning
listing missing optional tools. Install what you use with `:Mason` or your
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

## Optional CodeCompanion, images, Markdown, and MCP

AI plugins are **excluded from the spec** unless `DOTFILES_NVIM_AI=1`; they
aren't installed, loaded, or contacted by default. To install and enable them:

```sh
export DOTFILES_NVIM_AI=1
export DOTFILES_NVIM_AI_ENDPOINT=http://127.0.0.1:1234/v1/chat/completions
export DOTFILES_NVIM_AI_MODEL=your-server-model-id
# Optional: export DOTFILES_NVIM_AI_API_KEY=...
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

Keep the enable flag in your environment when launching Neovim. The endpoint is
the **complete OpenAI-compatible chat-completions URL**, defaulting to the local
LM Studio URL above. Set a model your server exposes (the placeholder default
is `local-model`). The configured model/choices are local values, not implicit
`/models` discovery. HTTP requests require `curl`. Prefer HTTPS for remote hosts.

`:CodeCompanionChat` opens chat; `:CodeCompanion explain this code` provides the
inline assistant; `:CodeCompanionActions` opens actions; `:CodeCompanionCmd`
provides command generation. Blink integrates CodeCompanion's chat completions.
The plugins load only on their commands/filetypes, not at startup. Chat/inline
actions may share selected code, buffers, or tools with the configured service;
review CodeCompanion's context and approval settings before use.

`render-markdown.nvim` renders Markdown/chat buffers with installed parsers.
`:PasteImage` retains img-clip's CodeCompanion absolute-path image template;
install your platform's clipboard image tools (`wl-paste`/`xclip` or macOS
`pngpaste`) as needed, and use a vision-capable model. Rendering/images aren't
AI requests by themselves.

MCPHub remains available via `:MCPHub` when AI is enabled. Its external daemon is
**not bundled or installed by startup/setup**: install Node.js and the pinned
`mcp-hub@4.2.0` binary explicitly (for example `npm install -g mcp-hub@4.2.0`).
Configure trusted servers in `~/.config/mcphub/servers.json`. To connect MCPHub's
tools/resources/prompts to CodeCompanion, additionally set
`DOTFILES_NVIM_MCP=1` before starting Neovim. This loads MCPHub on the first
explicit CodeCompanion command; otherwise start its UI explicitly. Automatic
tool approval and LLM-driven server toggles are disabled. Starting MCPHub may
start configured local servers or contact configured remote servers; audit that
configuration first. There is no npm build/download hook.

## Tests

```sh
just test
```

The Bats suite launches real headless Neovim in private HOME/XDG directories and
never downloads plugins or parsers. It checks offline defaults, locked plugin
specs, the server set, TODO mappings, and default-disabled AI. Fuzzy picker tests
capture dispatch, not a real interactive fzf terminal session. Lua assertions
run directly inside Neovim; no embedded client or Python test framework is used.

Validation for the restored configuration: 11 headless tests and full plugin smoke
on 0.11.3/0.11.6 with AI disabled/enabled;
explicit installation of all 27 locked
repositories and all 18 locked parser grammars; real CodeCompanion chat creation
with the HTTP functions blocked to catch accidental model discovery. The real
MCPHub extension also registers against CodeCompanion with its daemon stubbed. Actual
model responses, MCP daemon calls, interactive fzf, language-server conversations,
formatter binaries, and terminal clipboard round trips aren't covered by those
smoke checks. Re-run explicit setup and smoke checks when updating revisions.

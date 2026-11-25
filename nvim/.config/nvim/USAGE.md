# Neovim usage

Leader is **Space**. Press Space and pause for which-key, or Space ? for all mappings. Start Neovim from your project directory.

## Project dashboard

Run `nvim` without a file to open the dashboard, or press Space h to reopen
it. Neovim uses the Git root when started in a repository, otherwise the current
directory. The dashboard displays the project path, Git branch and status when
available, and recent files from that project. It does not change your working
directory. Opening a file directly (for example, `nvim file.lua`) skips it.

While the dashboard is focused:

| Key | Action |
| --- | --- |
| p | Switch project |
| f | Find project files |
| g | Search the project; without `rg`, use the Vim-regex fallback |
| e | Open the project explorer |
| o | Toggle the OpenCode terminal (uses Neovim's working directory) |
| c | Browse Neovim configuration |
| q | Quit Neovim |

Recent files have numbered shortcuts shown next to them. Press Escape to close
a reopened floating dashboard. Reopen the dashboard after changing directories
to refresh its project context.

## Navigation

| Keys | Action |
| --- | --- |
| Space ff / fg | Find files (including hidden files) / search project text (requires `rg`) |
| Space fp / fs | Switch project / find current-file symbols with Aerial and Snacks |
| Space fb / fc | Find buffers / commands |
| Space fh / fk | Find help / keymaps |
| Space e / fe | Open explorer / reveal current file |
| Space uo | Toggle the Aerial symbol outline |
| Space uz / um | Toggle Zen / toggle rendering in this Markdown buffer |
| Ctrl-h/j/k/l | Move between windows |

In a picker type to filter, use arrows or Ctrl-j/Ctrl-k, and press Enter. Ctrl-c cancels; Alt-h toggles hidden files. Tab selects items; Alt-o sends them to OpenCode. In the explorer Enter opens, h closes a directory, a creates, r renames, d deletes, c copies, m moves, and H toggles hidden files (dotfiles are shown by default). Press ? for action help. Review file-operation prompts carefully.

File search includes hidden files by default but still respects ignore rules such as `.gitignore`.

The Aerial outline uses Treesitter or an available language server to find symbols. In the outline, Enter jumps to a symbol, h/l collapse or expand a branch, and q closes it; press ? for help.

The project picker lists the current directory, Git roots from recent files, and repositories directly under `~/GitHub`. Selecting a project changes the current tab's working directory and opens its dashboard; it does not close unsaved buffers. Non-Git projects appear when current, but are not otherwise tracked in history.

## OpenCode

| Keys | Action |
| --- | --- |
| Space oa | Ask about cursor or visual selection |
| Space os | Select an action such as explain or review |
| Space ot | Toggle the OpenCode terminal |
| Space oe / or / od | Explain / review selection or cursor / explain diagnostics |
| go + motion / goo | Send a range / the current line |

Start an OpenCode session with Space ot, then ask with Space oa. The plugin can discover a running compatible OpenCode service, or start one in a terminal. It targets the most recently updated session for Neovim's directory. Save changes first: OpenCode reads files from disk. Contexts include `@this`, `@buffer`, `@diagnostics`, and `@visible`. Requests may share context with the configured model; permission prompts require approval. Run `:checkhealth opencode` for diagnostics. Space oe/or/od send their preset prompts immediately; lualine displays connection and activity once OpenCode is loaded.

Diagnostics appear inline on affected lines. Use ]d and [d to jump between them; Space cd shows the full message for the current line.

## Code and Git

| Keys | Action |
| --- | --- |
| Space ca / cr / cd | Code actions / rename / line diagnostics |
| Space cD | Search diagnostics in the current file |
| Space cf or Space m | Format buffer |
| K / grr / gri / grn | Hover / references / implementations / rename |
| Space / | Toggle comments in normal or visual mode |
| ]h / [h | Next / previous Git hunk |
| Space gh / gs / gr | Preview / stage / reset hunk |
| Space gb | Blame line |
| Space gg / gl | Git status / commit history |
| Space gd / gf | Diffview / current-file history |
| Space tn / tp | Next / previous TODO |
| Space tf / ts | Search TODO text |

LSP actions require an installed language server. Use `:Mason` to manage servers and install formatters separately. See `:ConformInfo` and `:checkhealth vim.lsp`. Formatting runs on save when a suitable formatter or LSP is available.

Use `:DiffviewOpen`, `:DiffviewFileHistory`, and `:DiffviewClose` for Git diffs. Resetting a hunk changes your working file. Markdown renders headings, task boxes and code blocks when Treesitter parsers are installed; Space um toggles rendering only for the current Markdown buffer without changing file contents. Space uz toggles distraction-free Zen mode. The theme is Catppuccin Mocha.

## Setup and fallback

Normal startup does not install plugins or parsers. After linking dotfiles on a new machine, install the reviewed plugin versions explicitly:

```sh
env -u DOTFILES_SKIP_PLUGIN_BOOTSTRAP nvim --headless -l "$HOME/.config/nvim/setup.lua"
```

Requires Neovim 0.12+, Git, network access, and `rg` for live search. A Nerd Font is recommended for icons. Without plugins, the editor falls back to netrw and built-in selection/search; fallback search uses Vim regex and returns quickfix results (`:cnext`/`:cprev`).

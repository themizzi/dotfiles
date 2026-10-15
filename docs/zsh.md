# Zsh

Stow the `zsh` package as usual. `.zshenv` only supplies XDG defaults and
`NANORC`; explicit non-empty values are preserved, including for scripts.
`.zprofile` and `.zshrc` share executable discovery in
`~/.zsh/environment.zsh`. A `brew` executable already on PATH wins; otherwise
ARM macOS, Intel macOS, then Linux Homebrew are checked. Only one `shellenv`
is evaluated per shell. No Apple-specific directories are added on Linux
unless they actually exist or the selected Homebrew supplies them.

## Plugins (explicit network access)

Initialize the canonical Antidote submodule from the repository:

```sh
git submodule update --init zsh/.antidote
```

Then start interactive zsh and run `dotfiles-plugins-update`. This explicitly
runs `antidote bundle` against `~/.zsh_plugins.txt` and may download plugins.
Restart zsh to use the resulting `$XDG_CACHE_HOME/zsh/plugins.zsh`. Startup
only sources that cache: it never runs `antidote load`, clones repositories,
or automatically refreshes a stale bundle. Repeat the command after changing
the plugin list; use Antidote's `update` command explicitly to update clones.
Without a cache the shell works without plugins. The cached bundle prepares
plugin completion paths before the single guarded `compinit` invocation.
Early plugin `compdef` calls are queued and replayed after initialization.

If the submodule is missing, the selected Homebrew prefix's Antidote is used.
`DOTFILES_ANTIDOTE_HOMEBREW_PATH` can explicitly select a compatibility script;
an empty value disables that fallback. The submodule still takes precedence.
Only point this variable at trusted shell code.

## Local settings and state

Put optional private settings in `~/.zshrc.local` (loaded last). Create it as
a regular file outside the repository, owned by you, with mode 600
(`chmod 600 ~/.zshrc.local`). If placed beside the stowed source `.zshrc`,
that filename is ignored by the repository's `.gitignore`; do not commit credentials.
These files and plugin bundles execute arbitrary code, so keep their parent
directories non-writable by other users. `compinit` retains security checks.

History is `$XDG_STATE_HOME/zsh/history`, with 50,000 in-memory entries and
10,000 saved entries, incremental append, duplicate suppression, and reduced
blanks. New history directories are private. Editor defaults prefer nvim,
vim, nano, then vi, without replacing explicit `EDITOR` or `VISUAL` values.
NVM loads from `$NVM_DIR/nvm.sh` (default `~/.nvm`) or the selected Homebrew
prefix. Starship and Hugo completion are optional; Starship is skipped for
`TERM=dumb`. No browser is overridden.

If an old `~/.zshrc.zwc` masks changes, remove that compiled file explicitly.
Run isolated startup checks with:

```sh
python3 -m unittest discover -s test -p 'test_zsh.py' -v
```

Tests require zsh, but no Python dependencies or network.

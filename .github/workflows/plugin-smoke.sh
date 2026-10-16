#!/bin/sh
# Explicit network integration: install locked plugins in a disposable HOME.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P)
TEMP=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-plugin-smoke.XXXXXX")
trap 'rm -rf "$TEMP"' EXIT HUP INT TERM
unset ENV BASH_ENV ZDOTDIR VIMINIT EXINIT GVIMINIT MYVIMRC MYGVIMRC NVIM NVIM_APPNAME
unset NVIM_LISTEN_ADDRESS VIM VIMRUNTIME LUA_PATH LUA_CPATH XDG_CONFIG_HOME XDG_DATA_HOME
unset XDG_STATE_HOME XDG_CACHE_HOME XDG_RUNTIME_DIR XDG_CONFIG_DIRS XDG_DATA_DIRS
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM
unset GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS DOTFILES_NVIM_AI_API_KEY DOTFILES_NVIM_MCP
mkdir -p "$TEMP/config" "$TEMP/data" "$TEMP/state" "$TEMP/cache" "$TEMP/runtime" "$TEMP/tmp"
cp -R "$ROOT/nvim/.config/nvim" "$TEMP/config/nvim"
cp "$ROOT/vim/.vimrc" "$TEMP/.vimrc"
export HOME="$TEMP" XDG_CONFIG_HOME="$TEMP/config" XDG_DATA_HOME="$TEMP/data"
export XDG_STATE_HOME="$TEMP/state" XDG_CACHE_HOME="$TEMP/cache" XDG_RUNTIME_DIR="$TEMP/runtime"
export TMPDIR="$TEMP/tmp" TMP="$TEMP/tmp" GIT_CONFIG_GLOBAL="$TEMP/.gitconfig" GIT_CONFIG_NOSYSTEM=1
export DOTFILES_NVIM_AI=0
config="$XDG_CONFIG_HOME/nvim"
printf '%s\n' 'Installing the reviewed plugin lock (network access required)...'
nvim --headless -l "$config/setup.lua"
cat > "$TEMP/probe.lua" <<'LUA'
local ok, err = pcall(function()
  assert(vim.v.errmsg == '', vim.v.errmsg)
  assert(require('lazy'), 'lazy.nvim failed to load')
  assert(require('fzf-lua'), 'fzf-lua failed to load')
  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'), '\n'))
  for _, plugin in pairs(require('lazy.core.config').plugins) do
    assert(vim.fn.isdirectory(plugin.dir) == 1, 'missing plugin: ' .. plugin.name)
    local head = vim.system({'git', '-C', plugin.dir, 'rev-parse', 'HEAD'}, {text = true}):wait()
    assert(lock[plugin.name] and head.code == 0 and vim.trim(head.stdout) == lock[plugin.name].commit,
      'Plugin revision differs from reviewed lock: ' .. plugin.name)
  end
end)
if not ok then
  io.stderr:write(tostring(err) .. '\n')
  vim.cmd('cquit 1')
else
  vim.cmd('qa!')
end
LUA
nvim --headless -c "lua dofile('$TEMP/probe.lua')"
printf '%s\n' 'Plugin startup and locked revisions verified.'

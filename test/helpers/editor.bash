# Private Neovim fixture: never expose writable source-tree symlinks to the editor.
editor_fixture() {
    EDITOR_ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    EDITOR_HOME="$BATS_TEST_TMPDIR/editor home"
    EDITOR_BIN="$EDITOR_HOME/bin"
    mkdir -p "$EDITOR_HOME" "$EDITOR_BIN" "$EDITOR_HOME/config" \
        "$EDITOR_HOME/data" "$EDITOR_HOME/state" "$EDITOR_HOME/cache" \
        "$EDITOR_HOME/runtime" "$EDITOR_HOME/tmp" "$EDITOR_HOME/config-dirs" \
        "$EDITOR_HOME/data-dirs" "$EDITOR_HOME/workspace"
    cp -R "$EDITOR_ROOT/nvim/.config/nvim" "$EDITOR_HOME/config/nvim"
    cp "$EDITOR_ROOT/vim/.vimrc" "$EDITOR_HOME/.vimrc"
    printf 'alpha fixture line\nsecond needle\n' > "$EDITOR_HOME/workspace/alpha.txt"
    printf 'beta fixture line\n' > "$EDITOR_HOME/workspace/beta.txt"
    NVIM_BIN=$(command -v nvim)
    [ -x "$NVIM_BIN" ] || { echo 'nvim required for editor tests' >&2; return 1; }
    cat > "$EDITOR_HOME/test-wrapper.lua" <<'LUA'
local ok, err = xpcall(function() dofile(vim.env.DOTFILES_LUA_TEST) end, debug.traceback)
if not ok then io.stderr:write(err); vim.cmd('cquit 1') else vim.cmd('qa!') end
LUA
    cd "$EDITOR_HOME/workspace"
}

run_editor_lua() {
    local test_file=$1
    local ai=0
    [ "$test_file" = ai.lua ] && ai=1
    run env -i \
        HOME="$EDITOR_HOME" PATH="${PATH:-/usr/bin:/bin}" \
        XDG_CONFIG_HOME="$EDITOR_HOME/config" XDG_DATA_HOME="$EDITOR_HOME/data" \
        XDG_STATE_HOME="$EDITOR_HOME/state" XDG_CACHE_HOME="$EDITOR_HOME/cache" \
        XDG_RUNTIME_DIR="$EDITOR_HOME/runtime" XDG_CONFIG_DIRS="$EDITOR_HOME/config-dirs" \
        XDG_DATA_DIRS="$EDITOR_HOME/data-dirs" TMPDIR="$EDITOR_HOME/tmp" TMP="$EDITOR_HOME/tmp" \
        DOTFILES_SKIP_PLUGIN_BOOTSTRAP=1 DOTFILES_NVIM_AI="$ai" \
        DOTFILES_NVIM_AI_API_KEY= DOTFILES_NVIM_MCP=0 GIT_CONFIG_GLOBAL="$EDITOR_HOME/gitconfig" \
        GIT_CONFIG_NOSYSTEM=1 DOTFILES_LUA_TEST="$EDITOR_ROOT/test/neovim/$test_file" \
        "$NVIM_BIN" --headless -c "lua dofile('$EDITOR_HOME/test-wrapper.lua')"
    if [ "$status" -eq 0 ]; then
        [ -d "$EDITOR_HOME/config/nvim" ] && [ ! -L "$EDITOR_HOME/config/nvim" ]
        [ ! -e "$EDITOR_HOME/data/nvim/lazy" ]
    fi
}

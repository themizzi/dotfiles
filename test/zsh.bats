#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

setup() {
    ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    HOME="$BATS_TEST_TMPDIR/test home"
    BIN="$HOME/bin"
    mkdir -p "$HOME" "$BIN"
    for file in .zshenv .zprofile .zshrc .zsh_plugins.txt; do cp "$ROOT/zsh/$file" "$HOME/$file"; done
    cp -R "$ROOT/zsh/.zsh" "$HOME/.zsh"
    PATH="$BIN:/usr/bin:/bin"
    export HOME ZDOTDIR="$HOME" PATH TERM=dumb LC_ALL=C DOTFILES_ANTIDOTE_HOMEBREW_PATH=
    printf '#!/bin/sh\necho unexpected-network >&2; exit 99\n' > "$BIN/git"
    cp "$BIN/git" "$BIN/curl"
    cp "$BIN/git" "$BIN/wget"
    chmod +x "$BIN/git" "$BIN/curl" "$BIN/wget"
}

write_file() {
    local path=$1
    mkdir -p "$(dirname "$path")"
    cat > "$path"
}

run_zsh() {
    local flags=$1 command=$2
    shift 2
    run env -i \
        HOME="$HOME" ZDOTDIR="$HOME" PATH="$PATH" TERM=dumb LC_ALL=C \
        DOTFILES_ANTIDOTE_HOMEBREW_PATH="${DOTFILES_ANTIDOTE_HOMEBREW_PATH-}" "$@" \
        zsh -d "$flags" "$command"
}

fake_brew() {
    BREW_PREFIX="$HOME/brew prefix"
    cat > "$BIN/brew" <<SH
#!/bin/sh
[ "\$1" = shellenv ] || exit 1
echo call >> "\$HOME/brew-calls"
printf "export HOMEBREW_PREFIX='%s'\\n" '$BREW_PREFIX'
SH
    chmod +x "$BIN/brew"
}

fake_antidote() {
    local file=$1 selected=$2
    write_file "$file" <<SH
ANTIDOTE_SELECTED=$selected
antidote() {
  print -r -- "\$1" >> "\$HOME/antidote-calls"
  [[ \$1 == bundle ]] || return 99
  print -r -- '_zsh_highlight() { :; }'
}
SH
}

@test "noninteractive environment is quiet and minimal" {
    fake_brew
    mkdir -p "$HOME/.cargo"
    printf '%s\n' 'print -u2 "must not load cargo"' > "$HOME/.cargo/env"
    run_zsh -c ':'
    assert_success
    refute_output
    [ ! -e "$HOME/brew-calls" ]
    [ ! -e "$HOME/.local/state" ]
}

@test "explicit XDG settings survive and nano follows config home" {
    run_zsh -c 'print -rl -- "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$NANORC"' \
        XDG_CONFIG_HOME="$HOME/config custom" XDG_CACHE_HOME="$HOME/cache custom" \
        XDG_DATA_HOME="$HOME/data custom" XDG_STATE_HOME="$HOME/state custom"
    assert_success
    assert_output "$HOME/config custom
$HOME/cache custom
$HOME/data custom
$HOME/state custom
$HOME/config custom/nano/nanorc"
}

@test "interactive startup configures history and private state" {
    run_zsh -ic 'print -r -- "$HISTFILE|$HISTSIZE|$SAVEHIST|$options[incappendhistory]|$options[histignoredups]"'
    assert_success
    assert_output "$HOME/.local/state/zsh/history|50000|10000|on|on"
    [ "$(stat -c '%a' "$HOME/.local/state/zsh" 2>/dev/null || stat -f '%Lp' "$HOME/.local/state/zsh")" = 700 ]
    [ -f "$HOME/.cache/zsh/zcompdump" ]
}

@test "login and interactive startup discover Homebrew only once" {
    fake_brew
    run_zsh -lic 'source ~/.zshrc; :'
    assert_success
    [ "$(wc -l < "$HOME/brew-calls")" -eq 1 ]
}

@test "login startup gets Homebrew tools without interactive state" {
    fake_brew
    run_zsh -lc 'print -r -- "$HOMEBREW_PREFIX"'
    assert_success
    assert_output "$BREW_PREFIX"
    [ ! -e "$HOME/.local/state/zsh" ]
}

@test "PATH is unique and includes existing optional directories" {
    fake_brew
    mkdir -p "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"
    run_zsh -ic 'source ~/.zshrc; print -rl -- $path' PATH="$BIN:/usr/bin:/bin:/usr/bin"
    assert_success
    [ "$(printf '%s\n' "$output" | sort -u | wc -l)" -eq "$(printf '%s\n' "$output" | wc -l)" ]
    [[ "$output" == *"$HOME/.local/bin"* && "$output" == *"$HOME/.cargo/bin"* && "$output" == *"$HOME/go/bin"* ]]
    [[ "$output" != *"$HOME/.lmstudio/bin"* && "$output" != *"/opt/homebrew/opt/rustup/bin"* ]]
}

@test "editor and browser overrides survive and Neovim is a fallback" {
    run_zsh -ic 'print -r -- "$EDITOR|$VISUAL|$BROWSER"' EDITOR='my-editor --wait' VISUAL=my-visual BROWSER=desktop-browser
    assert_success
    assert_output 'my-editor --wait|my-visual|desktop-browser'
    printf '#!/bin/sh\nexit 0\n' > "$BIN/nvim"
    chmod +x "$BIN/nvim"
    run_zsh -ic 'print -r -- "$EDITOR|$VISUAL"'
    assert_success
    assert_output 'nvim|nvim'
}

@test "canonical Antidote wins and startup does not bundle" {
    fake_antidote "$HOME/.antidote/antidote.zsh" canonical
    fake_antidote "$HOME/compatibility/antidote.zsh" compatibility
    run_zsh -ic 'print -r -- "$ANTIDOTE_SELECTED"' DOTFILES_ANTIDOTE_HOMEBREW_PATH="$HOME/compatibility/antidote.zsh"
    assert_success
    assert_output canonical
    [ ! -e "$HOME/antidote-calls" ]
}

@test "explicit Antidote update creates an offline cache" {
    fake_antidote "$HOME/compatibility/antidote.zsh" compatibility
    run_zsh -ic 'dotfiles-plugins-update' DOTFILES_ANTIDOTE_HOMEBREW_PATH="$HOME/compatibility/antidote.zsh"
    assert_success
    [ "$(cat "$HOME/antidote-calls")" = bundle ]
    rm "$HOME/compatibility/antidote.zsh"
    run_zsh -ic 'whence -w _zsh_highlight' DOTFILES_ANTIDOTE_HOMEBREW_PATH="$HOME/compatibility/antidote.zsh"
    assert_success
    assert_output '_zsh_highlight: function'
    [ "$(cat "$HOME/antidote-calls")" = bundle ]
}

@test "failed Antidote update preserves previous cache" {
    mkdir -p "$HOME/.cache/zsh"
    printf '# previous bundle\n' > "$HOME/.cache/zsh/plugins.zsh"
    mkdir -p "$HOME/.antidote"
    printf 'antidote() { print broken; return 1; }\n' > "$HOME/.antidote/antidote.zsh"
    run_zsh -ic 'if dotfiles-plugins-update; then exit 9; fi'
    assert_success
    [ "$(cat "$HOME/.cache/zsh/plugins.zsh")" = '# previous bundle' ]
    [ -z "$(find "$HOME/.cache/zsh" -name 'plugins.zsh.*' -print -quit)" ]
}

@test "explicit NVM_DIR overrides Homebrew and Homebrew fallback remains available" {
    fake_brew
    mkdir -p "$BREW_PREFIX/opt/nvm" "$HOME/custom nvm"
    printf 'export NVM_SELECTED=brew\n' > "$BREW_PREFIX/opt/nvm/nvm.sh"
    printf 'export NVM_SELECTED=custom\n' > "$HOME/custom nvm/nvm.sh"
    run_zsh -ic 'print -r -- "$NVM_SELECTED"' \
        HOMEBREW_PREFIX="$BREW_PREFIX" NVM_DIR="$HOME/custom nvm"
    assert_success
    assert_output custom
    run_zsh -ic 'print -r -- "$NVM_SELECTED"' \
        HOMEBREW_PREFIX="$BREW_PREFIX" NVM_DIR="$HOME/missing nvm"
    assert_success
    assert_output brew
}

@test "user local override is sourced last" {
    printf 'export EDITOR=private-editor\n' > "$HOME/.zshrc.local"
    run_zsh -ic 'print -r -- "$EDITOR"'
    assert_success
    assert_output private-editor
}

@test "all shipped Zsh sources parse without execution" {
    while IFS= read -r -d '' file; do
        case "${file##*/}" in .zshenv|.zprofile|.zshrc) ;; *) [ "${file##*.}" = zsh ] || continue ;; esac
        run zsh -n "$file"
        assert_success "$output"
    done < <(find "$ROOT/zsh" -type f -print0)
}

# First-party fixture helpers. All installer writes stay in BATS_TEST_TMPDIR.
# Bats tests consume the fixture variables declared here.
# shellcheck disable=SC2034
installer_fixture() {
    SOURCE_ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    REAL_STOW=$(command -v stow)
    FIXTURE="$BATS_TEST_TMPDIR/installer tests"
    REPO="$FIXTURE/repo with spaces"
    TARGET_HOME="$FIXTURE/home with spaces"
    TOOLS="$FIXTURE/bin"
    CALLS="$FIXTURE/calls"
    mkdir -p "$REPO" "$TARGET_HOME" "$TOOLS" "$CALLS"
    cp "$SOURCE_ROOT/install.sh" "$REPO/install.sh"
    ALL_PACKAGES=(gh gh-copilot nano nvim starship vim zsh)
    PACKAGES=(gh nano nvim starship vim zsh)
    mkdir -p "$REPO/scripts" "$REPO/packages"
    cp -R "$SOURCE_ROOT/profiles" "$REPO/profiles"
    cp "$SOURCE_ROOT/scripts/profile-packages.sh" "$REPO/scripts/"
    cp "$SOURCE_ROOT/packages/cli.tsv" "$REPO/packages/"
    cp "$SOURCE_ROOT"/packages/Brewfile.* "$REPO/packages/"
    for package in "${ALL_PACKAGES[@]}"; do
        mkdir -p "$REPO/$package"
        printf '%s\n' "$package" > "$REPO/$package/.$package"
    done
    rm "$REPO/vim/.vim" "$REPO/nvim/.nvim"
    cp "$SOURCE_ROOT/vim/.vimrc" "$REPO/vim/.vimrc"
    mkdir -p "$REPO/nvim/.config/nvim"
    cp "$SOURCE_ROOT/nvim/.config/nvim/init.vim" "$REPO/nvim/.config/nvim/init.vim"
    for tool in dirname cat grep find awk sh tr sort; do
        ln -s "$(command -v "$tool")" "$TOOLS/$tool"
    done
    cat > "$TOOLS/git" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$CALLS/git"
[ "$1" = -C ] && [ "$2" = "$(pwd -P)" ] &&
    [ "$3" = submodule ] && [ "$4" = status ] && [ "$5" = --recursive ] || exit 90
shift 5
if [ "$#" = 0 ]; then
    printf '%s\n' '-abc vendor/bats-core'
else
    [ "$1" = -- ] || exit 91
    printf '%s\n' "$SUBMODULE_STATUS"
fi
exit "$GIT_FAILURE"
SH
    cat > "$TOOLS/stow" <<'SH'
#!/bin/sh
count=0
if [ -f "$CALLS/count" ]; then read -r count < "$CALLS/count"; fi
count=$((count + 1))
printf '%s\n' "$count" > "$CALLS/count"
printf '%s\n' "$@" > "$CALLS/stow-$count"
exit "$STOW_FAILURE"
SH
    chmod +x "$TOOLS/git" "$TOOLS/stow"
    XDG_ROOT="$TARGET_HOME/.config"
    SUBMODULE_STATUS=' ready zsh/.antidote'
    GIT_FAILURE=0
    STOW_FAILURE=0
    cd "$FIXTURE" || return 1
}

run_installer() {
    run env HOME="$TARGET_HOME" XDG_CONFIG_HOME="$XDG_ROOT" PATH="$TOOLS" \
        CALLS="$CALLS" SUBMODULE_STATUS="$SUBMODULE_STATUS" \
        GIT_FAILURE="$GIT_FAILURE" STOW_FAILURE="$STOW_FAILURE" \
        /bin/sh "$REPO/install.sh" "$@"
}

assert_no_stow() { [ ! -f "$CALLS/count" ]; }
assert_call_count() { [ "$(cat "$CALLS/count")" = "$1" ]; }
assert_call_arg() { grep -F -x -- "$2" "$CALLS/stow-$1"; }
use_real_stow() {
    rm "$TOOLS/stow"
    ln -s "$REAL_STOW" "$TOOLS/stow"
}

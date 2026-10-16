#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'helpers/installer.bash'

setup() { installer_fixture; }

@test "help and invalid options need no installer dependencies" {
    rm "$TOOLS/stow" "$TOOLS/git"
    run_installer --help
    assert_success
    assert_output --partial 'Usage:'
    run_installer --adopt
    assert_failure
    assert_no_stow
}

@test "missing Stow fails before changes" {
    rm "$TOOLS/stow"
    run_installer
    assert_failure
    assert_output --partial 'required'
    assert_no_stow
}

@test "missing Git fails before changes" {
    rm "$TOOLS/git"
    run_installer
    assert_failure
    assert_output --partial 'required'
    assert_no_stow
}

@test "uninitialized or conflicted application submodules fail before Stow" {
    for SUBMODULE_STATUS in '-abc zsh/.antidote' 'Uabc nano/nanorc.d' ''; do
        run_installer --dry-run
        assert_failure
        assert_no_stow
        [ ! -e "$TARGET_HOME/.vimrc" ]
    done
}

@test "Git inspection failure has no side effects" {
    GIT_FAILURE=1
    run_installer
    assert_failure
    assert_output --partial 'Cannot inspect submodules'
    assert_no_stow
}

@test "only application submodules are inspected, not missing vendor dependencies" {
    mkdir "$REPO/vendor"
    run_installer --dry-run
    assert_success
    grep -F -x -- '--' "$CALLS/git"
    ! grep -F 'vendor' "$CALLS/git"
}

@test "paths with spaces preflight the complete selection before apply" {
    run_installer
    assert_success
    assert_call_count 2
    assert_call_arg 1 --simulate
    assert_call_arg 2 "--dir=$(cd "$REPO" && pwd -P)"
    assert_call_arg 2 "--target=$TARGET_HOME"
    assert_call_arg 2 --stow
    for package in "${PACKAGES[@]}"; do assert_call_arg 2 "$package"; done
    ! grep -E -- '--restow|--adopt' "$CALLS/stow-2"
}

@test "dry run preserves existing files and does not apply" {
    printf 'valuable\n' > "$TARGET_HOME/.vimrc"
    run_installer --dry-run
    assert_success
    assert_call_count 1
    assert_call_arg 1 --simulate
    [ "$(cat "$TARGET_HOME/.vimrc")" = valuable ]
    [ ! -e "$TARGET_HOME/.config" ]
}

@test "failed preflight preserves configuration without applying" {
    printf 'valuable\n' > "$TARGET_HOME/.vimrc"
    STOW_FAILURE=1
    run_installer
    assert_failure
    assert_output --partial 'preflight failed'
    assert_call_count 1
    [ "$(cat "$TARGET_HOME/.vimrc")" = valuable ]
}

@test "unlink needs neither Git nor initialized submodules" {
    rm "$TOOLS/git"
    run_installer --unlink
    assert_success
    assert_call_count 2
    assert_call_arg 1 --delete
    assert_call_arg 2 --delete
}

@test "unlink dry run only simulates" {
    run_installer --unlink --dry-run
    assert_success
    assert_call_count 1
    assert_call_arg 1 --delete
    assert_call_arg 1 --simulate
}

@test "ambient Stow options cannot enable adoption or overrides" {
    for directory in "$TARGET_HOME" "$REPO"; do
        printf '%s\n' --adopt '--override=.*' > "$directory/.stowrc"
        run_installer
        assert_failure
        assert_output --partial 'Stow options file'
        grep -F -x -- --adopt "$directory/.stowrc"
        rm "$directory/.stowrc"
    done
    assert_no_stow
}

@test "missing package fails before Stow" {
    rm "$REPO/gh/.gh"
    rmdir "$REPO/gh"
    run_installer
    assert_failure
    assert_output --partial 'Missing package'
    assert_no_stow
}

@test "HOME must be an existing absolute directory" {
    for TARGET_HOME in relative '' "$FIXTURE/nonexistent"; do
        run_installer
        assert_failure
        assert_no_stow
    done
}

@test "malformed development venv is preserved before setup" {
    mkdir -p "$REPO/.devcontainer/scripts"
    cp "$SOURCE_ROOT/.devcontainer/scripts/post-create.sh" "$REPO/.devcontainer/scripts/"
    for kind in directory file symlink; do
        case "$kind" in
            directory) mkdir "$REPO/.venv"; printf keep > "$REPO/.venv/valuable" ;;
            file) printf keep > "$REPO/.venv" ;;
            symlink) ln -s "$REPO/missing" "$REPO/.venv" ;;
        esac
        run env HOME="$TARGET_HOME" PATH="$TOOLS" /bin/sh "$REPO/.devcontainer/scripts/post-create.sh"
        assert_failure
        assert_output --partial 'has not been deleted'
        case "$kind" in
            directory) [ "$(cat "$REPO/.venv/valuable")" = keep ]; rm "$REPO/.venv/valuable"; rmdir "$REPO/.venv" ;;
            file) [ "$(cat "$REPO/.venv")" = keep ]; rm "$REPO/.venv" ;;
            symlink) [ -L "$REPO/.venv" ]; rm "$REPO/.venv" ;;
        esac
    done
}

@test "real Stow links Vim and Neovim idempotently and safely unlinks" {
    use_real_stow
    run_installer --dry-run
    assert_success
    [ ! -e "$TARGET_HOME/.vimrc" ]
    for iteration in 1 2; do
        run_installer
        assert_success
        [ -L "$TARGET_HOME/.vimrc" ]
        [ "$TARGET_HOME/.vimrc" -ef "$REPO/vim/.vimrc" ]
        [ -L "$TARGET_HOME/.config/nvim/init.vim" ]
        [ "$TARGET_HOME/.config/nvim/init.vim" -ef "$REPO/nvim/.config/nvim/init.vim" ]
    done
    printf keep > "$TARGET_HOME/unrelated"
    run_installer --unlink --dry-run
    assert_success
    [ -L "$TARGET_HOME/.vimrc" ]
    for iteration in 1 2; do run_installer --unlink; assert_success; done
    [ ! -L "$TARGET_HOME/.vimrc" ]
    [ ! -L "$TARGET_HOME/.config/nvim/init.vim" ]
    [ "$(cat "$TARGET_HOME/unrelated")" = keep ]
}

@test "real Stow conflict leaves all selected packages untouched" {
    use_real_stow
    printf keep > "$TARGET_HOME/.vimrc"
    run_installer
    assert_failure
    [ "$(cat "$TARGET_HOME/.vimrc")" = keep ]
    [ ! -e "$TARGET_HOME/.config" ]
    [ ! -e "$TARGET_HOME/.gh" ]
}

@test "test wrapper diagnoses missing vendor without fetching anything" {
    mkdir "$REPO/scripts"
    cp "$SOURCE_ROOT/scripts/test-installer.sh" "$REPO/scripts/"
    run /bin/sh "$REPO/scripts/test-installer.sh"
    assert_failure
    assert_output --partial 'submodule update --init --recursive -- vendor'
    [ ! -e "$REPO/vendor" ]
}

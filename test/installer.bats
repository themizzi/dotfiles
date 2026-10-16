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
    run grep -F 'vendor' "$CALLS/git"
    assert_failure 1
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
    run grep -E -- '--restow|--adopt' "$CALLS/stow-2"
    assert_failure 1
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
    mkdir -p "$REPO/scripts"
    cp "$SOURCE_ROOT/scripts/test-installer.sh" "$REPO/scripts/"
    run /bin/sh "$REPO/scripts/test-installer.sh"
    assert_failure
    assert_output --partial 'submodule update --init --recursive -- vendor'
    [ ! -e "$REPO/vendor" ]
}

@test "test wrapper ignores host Bash startup and library overrides" {
    printf 'touch "%s"\n' "$FIXTURE/host-startup-ran" > "$FIXTURE/poison.bash"
    run env BASH_ENV="$FIXTURE/poison.bash" BATS_BASE_LIBDIR=nonexistent \
        /bin/sh "$SOURCE_ROOT/scripts/test-installer.sh" --count
    assert_success
    assert_output --regexp '^[0-9]+$'
    [ ! -e "$FIXTURE/host-startup-ran" ]
}

@test "profiles select only the requested packages" {
    run_installer --profile minimal --dry-run
    assert_success
    assert_call_arg 1 vim
    assert_call_arg 1 zsh
    run grep -F -x gh "$CALLS/stow-1"
    assert_failure 1
    run grep -F -x gh-copilot "$CALLS/stow-1"
    assert_failure 1
    run grep -F -x nano "$CALLS/git"
    assert_failure 1
    run_installer --profile personal --dry-run
    assert_success
    for package in "${ALL_PACKAGES[@]}"; do assert_call_arg 2 "$package"; done
}

@test "invalid profiles fail before Stow" {
    run_installer --profile
    assert_failure
    run_installer --profile ../dev
    assert_failure
    run_installer --profile unknown
    assert_failure
    assert_no_stow
}

@test "custom XDG config is rejected rather than silently ignored" {
    XDG_ROOT="$FIXTURE/custom config"
    run_installer --dry-run
    assert_failure
    assert_output --partial XDG_CONFIG_HOME
    assert_no_stow
    run_installer --profile minimal --dry-run
    assert_success
}

@test "real Stow unlink preserves unselected dangling links without partial changes" {
    use_real_stow
    run_installer --profile minimal
    assert_success
    ln -s "$REPO/gh-copilot/missing" "$TARGET_HOME/.unselected-dangling"
    run_installer --profile minimal --unlink
    assert_failure
    assert_output --partial 'dangling link'
    [ -L "$TARGET_HOME/.unselected-dangling" ]
    [ -L "$TARGET_HOME/.vimrc" ]
}

@test "dangling link protection also applies to a symlinked HOME" {
    use_real_stow
    ln -s "$TARGET_HOME" "$FIXTURE/home alias"
    ln -s "$REPO/gh-copilot/missing" "$TARGET_HOME/.unselected-dangling"
    TARGET_HOME="$FIXTURE/home alias"
    run_installer --profile minimal --unlink
    assert_failure
    assert_output --partial 'dangling link'
    [ -L "$TARGET_HOME/.unselected-dangling" ]
}

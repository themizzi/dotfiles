#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

setup() {
    ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    FIXTURE="$BATS_TEST_TMPDIR/just contracts"
    mkdir -p "$FIXTURE/scripts" "$FIXTURE/tools"
    cp "$ROOT/justfile" "$FIXTURE/justfile"
    for tool in sh git zsh python3 just; do
        path=$(command -v "$tool")
        [ -n "$path" ] && ln -s "$path" "$FIXTURE/tools/$tool"
    done
    PATH="$FIXTURE/tools:$PATH"
    export PATH
}

run_just() { run just --justfile "$FIXTURE/justfile" --working-directory "$FIXTURE" "$@"; }

@test "install forwards spaced and hostile-looking arguments without interpolation" {
    printf '%s\n' 'printf "<%s>\n" "$@"' > "$FIXTURE/install.sh"
    run_just install 'two words' '$(touch BAD)' "quote'\"" '' --flag
    assert_success
    assert_output --partial '<two words>'
    assert_output --partial '<$(touch BAD)>'
    assert_output --partial '<>'
    [ ! -e "$FIXTURE/BAD" ]
}

@test "installer task forwards Bats options exactly" {
    printf '%s\n' 'printf "<%s>\n" "$@"' > "$FIXTURE/scripts/test-installer.sh"
    run_just test-installer --filter 'paths with spaces' '$(touch BAD)'
    assert_success
    assert_output --partial '<--filter>'
    assert_output --partial '<paths with spaces>'
    assert_output --partial '<$(touch BAD)>'
    [ ! -e "$FIXTURE/BAD" ]
}

@test "full test task delegates Bats arguments unchanged" {
    printf '%s\n' 'printf "<%s>\n" "$@"' > "$FIXTURE/scripts/test.sh"
    run_just test --filter 'just contracts'
    assert_success
    assert_output --partial '<--filter>'
    assert_output --partial '<just contracts>'
}

@test "public task definitions use pinned Bats and do not require Python" {
    run grep -F 'test *args:' "$ROOT/justfile"
    assert_success
    run grep -F 'sh scripts/test.sh "$@"' "$ROOT/justfile"
    assert_success
    run grep -F 'scripts/test-installer.sh "$@"' "$ROOT/justfile"
    assert_success
    run grep -E 'unittest|\.venv/bin/python|behave' "$ROOT/justfile"
    assert_failure
}

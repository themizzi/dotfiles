#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

setup() {
    SOURCE_ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    FIXTURE="$BATS_TEST_TMPDIR/profile resolver"
    mkdir -p "$FIXTURE/profiles" "$FIXTURE/scripts" "$FIXTURE/packages"
    cp -R "$SOURCE_ROOT/profiles/." "$FIXTURE/profiles/"
    cp "$SOURCE_ROOT/scripts/profile-packages.sh" "$FIXTURE/scripts/"
    cp "$SOURCE_ROOT/packages/cli.tsv" "$FIXTURE/packages/"
    cp "$SOURCE_ROOT"/packages/Brewfile.* "$FIXTURE/packages/"
}

resolve_profile() {
    run sh "$FIXTURE/scripts/profile-packages.sh" "$@"
}

append_profile() { printf '%b\n' "$2" >> "$FIXTURE/profiles/$1.profile"; }
reset_profiles() {
    rm -rf "$FIXTURE/profiles"
    mkdir "$FIXTURE/profiles"
    cp -R "$SOURCE_ROOT/profiles/." "$FIXTURE/profiles/"
}

assert_invalid_profile() {
    resolve_profile "$@"
    assert_failure
}

@test "each public profile resolves to its exact package set" {
    resolve_profile --profile minimal
    assert_success
    assert_output $'vim\nzsh'
    resolve_profile --profile dev
    assert_success
    assert_output $'gh\nnano\nnvim\nstarship\nvim\nzsh'
    resolve_profile --profile desktop
    assert_success
    assert_output $'gh\nnano\nnvim\nstarship\nvim\nzsh'
    resolve_profile --profile personal
    assert_success
    assert_output $'gh\ngh-copilot\nnano\nnvim\nstarship\nvim\nzsh'
}

@test "profiles declare independent CLI groups and application bundles" {
    resolve_profile --profile minimal --kind cli-group
    assert_success
    assert_output 'base'
    resolve_profile --profile desktop --kind macos-bundle
    assert_success
    assert_output 'desktop'
    resolve_profile --profile personal --kind macos-bundle
    assert_success
    assert_output $'desktop\npersonal'
}

@test "default profile is dev" {
    resolve_profile
    assert_success
    local default=$output
    resolve_profile --profile dev
    assert_success
    [ "$output" = "$default" ]
}

@test "default follows profiles/default and new profile files are discovered" {
    printf 'personal\n' > "$FIXTURE/profiles/default"
    resolve_profile
    assert_success
    assert_output $'gh\ngh-copilot\nnano\nnvim\nstarship\nvim\nzsh'

    cat > "$FIXTURE/profiles/workstation.profile" <<'EOF'
extends minimal
package nvim
cli-group development
EOF
    resolve_profile --profile workstation
    assert_success
    assert_output $'nvim\nvim\nzsh'
}

@test "multiple inheritance deduplicates packages deterministically" {
    append_profile dev 'extends minimal\npackage vim\npackage gh'
    append_profile personal 'extends minimal\nextends desktop\npackage gh-copilot'
    resolve_profile --profile personal
    assert_success
    assert_output $'gh\ngh-copilot\nnano\nnvim\nstarship\nvim\nzsh'
}

@test "invalid names and command-line forms fail closed" {
    local name
    for name in '' unknown ../dev DEV '$(touch forbidden)' 'dev
personal'; do
        assert_invalid_profile --profile "$name"
    done
    assert_invalid_profile dev
    assert_invalid_profile --profile
    assert_invalid_profile --other dev
    assert_invalid_profile --profile dev extra
}

@test "cycles, unknown parents, and unsupported packages fail" {
    append_profile minimal 'extends personal'
    assert_invalid_profile --profile personal
    reset_profiles
    append_profile dev 'extends missing'
    assert_invalid_profile
    reset_profiles
    append_profile desktop 'package desktop'
    assert_invalid_profile --profile desktop
}

@test "profile metadata is parsed as data and malformed definitions are rejected" {
    local marker="$FIXTURE/executed"
    append_profile dev "touch $marker"
    assert_invalid_profile
    [ ! -e "$marker" ]
    rm -rf "$FIXTURE/profiles"
    mkdir "$FIXTURE/profiles"
    cp -R "$SOURCE_ROOT/profiles/." "$FIXTURE/profiles/"
    append_profile minimal 'package vim extra'
    assert_invalid_profile --profile minimal
    rm "$FIXTURE/profiles/dev.profile"
    assert_invalid_profile
}

@test "help describes supported invocation" {
    resolve_profile --help
    assert_success
    assert_output --partial 'Usage:'
}

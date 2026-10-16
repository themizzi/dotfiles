#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

setup() {
    ROOT=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    FIXTURE="$BATS_TEST_TMPDIR/package provisioning"
    BIN="$FIXTURE/bin"
    RELEASE="$FIXTURE/os-release"
    MARKER="$FIXTURE/manager-was-invoked"
    mkdir -p "$BIN"
    printf 'ID=debian\nVERSION_ID="13"\n' > "$RELEASE"
    for tool in apt-get pacman brew sudo curl wget; do
        cat > "$BIN/$tool" <<SH
#!/bin/sh
printf '%s\\n' '$tool' >> '$MARKER'
exit 97
SH
        chmod +x "$BIN/$tool"
    done
    export ROOT FIXTURE BIN RELEASE MARKER
}

run_packages() {
    run env PACKAGES_TESTING=1 PACKAGES_TEST_OS="${TEST_OS-Linux}" \
        PACKAGES_TEST_ARCH="${TEST_ARCH-x86_64}" PACKAGES_TEST_OS_RELEASE="$RELEASE" \
        PATH="$BIN:$PATH" bash "$ROOT/scripts/packages.sh" "$@"
    [ ! -e "$MARKER" ] || { echo 'a package/network command was executed' >&2; return 1; }
}

reset_release() { printf 'ID=%s\nVERSION_ID="%s"\n' "$1" "$2" > "$RELEASE"; }

@test "default dev provisioning is a dry run and never installs optional apps" {
    run_packages
    assert_success
    assert_output --partial 'Would run:'
    assert_output --partial 'apt-get install'
    assert_output --partial 'just'
    refute_output --partial 'antidote'
}

@test "minimal package selection is exact and excludes dev applications" {
    run_packages --profile minimal --list
    assert_success
    assert_output $'git\nstow\nzsh\nvim\npython3'
}

@test "apt list matches canonical manifest without duplicates" {
    run_packages --list
    assert_success
    [ "$output" = "$(awk '!/^#/ {print $3}' "$ROOT/packages/cli.tsv" | sed '/^-/d')" ]
    [ "$(printf '%s\n' "$output" | sort -u | wc -l)" -eq "$(printf '%s\n' "$output" | wc -l)" ]
    [[ "$output" != *starship* ]]
}

@test "manager mappings use native package names" {
    run_packages --manager apt --list
    assert_success
    [[ "$output" == *fd-find* && "$output" != *starship* ]]
    run_packages --manager pacman --list
    assert_success
    [[ "$output" == *github-cli* && "$output" != *$'\ngh\n'* ]]
    run_packages --manager brew --list
    assert_success
    [[ "$output" == *$'\nfd\n'* && "$output" != *antidote* ]]
}

@test "canonical manifest schema and Homebrew policy are valid" {
    while read -r tier command apt pacman brew; do
        [[ -n "$tier" && "$tier" != \#* ]] || continue
        [[ "$tier" == minimal || "$tier" == dev ]]
        [[ "$command" =~ ^[a-z0-9-]+$ && "$apt" =~ ^[A-Za-z0-9-]+$ && "$pacman" =~ ^[A-Za-z0-9-]+$ && "$brew" =~ ^[A-Za-z0-9-]+$ ]]
    done < "$ROOT/packages/cli.tsv"
    grep -F 'packages/cli.tsv' "$ROOT/Brewfile"
    ! grep -F 'brew "antidote"' "$ROOT/Brewfile"
    grep -F 'brew "mas"' "$ROOT/packages/Brewfile.personal"
    [ ! -e "$ROOT/Brewfile.lock.json" ]
}

@test "supported Linux releases and architectures select the right adapter" {
    reset_release debian 13; run_packages; assert_success; assert_output --partial apt-get
    reset_release ubuntu 24.04; run_packages; assert_success; assert_output --partial apt-get
    reset_release ubuntu 26.04; run_packages; assert_success; assert_output --partial apt-get
    reset_release arch ''; run_packages; assert_success; assert_output --partial pacman
    TEST_ARCH=aarch64 run_packages; assert_success; assert_output --partial pacman
}

@test "unsupported operating systems, releases, and architectures fail closed" {
    reset_release debian 12; run_packages; assert_failure; assert_output --partial 'Supported Debian'
    reset_release ubuntu 22.04; run_packages; assert_failure; assert_output --partial 'Ubuntu 24.04+'
    reset_release fedora 43; run_packages; assert_failure; assert_output --partial 'Unsupported distro'
    reset_release unknown 99; run_packages; assert_failure; assert_output --partial 'Unsupported distro'
    TEST_OS=Darwin TEST_ARCH=mips run_packages; assert_failure; assert_output --partial 'architecture'
}

@test "OS release metadata and invalid values are never executed" {
    reset_release '$(touch marker)' 13
    run_packages; assert_failure
    [ ! -e "$FIXTURE/marker" ]
    run_packages --profile '$(touch marker)'; assert_failure
    run_packages --manager 'apt;false'; assert_failure
    run_packages --profile; assert_failure
    run_packages --bogus; assert_failure
    [ ! -e "$FIXTURE/marker" ]
}

@test "test seam and manager overrides cannot perform installs" {
    run_packages --install
    assert_failure
    assert_output --partial 'cannot install'
    run env PACKAGES_TESTING=0 PATH="$BIN:$PATH" bash "$ROOT/scripts/packages.sh" --manager apt --install
    assert_failure
    assert_output --partial 'cannot install'
    [ ! -e "$MARKER" ]
}

@test "macOS desktop and personal bundles are separate explicit previews" {
    TEST_OS=Darwin TEST_ARCH=arm64 run_packages
    assert_success
    assert_output --partial 'brew install'
    refute_output --partial 'brew bundle'
    refute_output --partial sudo
    TEST_OS=Darwin TEST_ARCH=arm64 run_packages --profile desktop
    assert_success
    assert_output --partial 'Brewfile.desktop'
    refute_output --partial 'Brewfile.personal'
    TEST_OS=Darwin TEST_ARCH=arm64 run_packages --profile personal
    assert_success
    assert_output --partial 'Brewfile.desktop'
    assert_output --partial 'Brewfile.personal'
}

@test "Linux personal profile reports its macOS-only application limitation" {
    run_packages --profile personal
    assert_success
    assert_output --partial 'macOS-only'
}

@test "doctor rejects Neovim older than minimum and accepts current versions" {
    for tool in git stow zsh vim python3 fzf fdfind rg gh nano just pip3 unzip gcc htop http git-lfs ps shellcheck; do
        printf '#!/bin/sh\nexit 0\n' > "$BIN/$tool"
        chmod +x "$BIN/$tool"
    done
    for version in 0.9.5 0.10.4 0.11.0 0.11.2 garbage; do
        cat > "$BIN/nvim" <<SH
#!/bin/sh
echo 'NVIM v$version'
SH
        chmod +x "$BIN/nvim"
        run_packages --doctor
        assert_failure
        assert_output --partial 'Neovim >=0.11.3 required'
    done
    for version in 0.11.3 0.11.6 0.12.0-dev 1.0.0; do
        cat > "$BIN/nvim" <<SH
#!/bin/sh
echo 'NVIM v$version'
SH
        chmod +x "$BIN/nvim"
        run_packages --doctor
        assert_success
        refute_output --partial 'Neovim >=0.11.3 required'
    done
}

@test "container consumes the shared manifest and avoids bootstrap downloads" {
    grep -F 'COPY packages/' "$ROOT/.devcontainer/Dockerfile"
    grep -F 'packages.sh --install --profile dev' "$ROOT/.devcontainer/Dockerfile"
    ! grep -E 'curl -fsSL|git clone' "$ROOT/.devcontainer/Dockerfile"
}

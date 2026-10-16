#!/usr/bin/env sh
set -eu

usage() {
    cat <<'EOF'
Usage: install.sh [--profile NAME] [--dry-run] [--unlink] [--help]

Link the selected profile into HOME using GNU Stow (default from profiles/default).
  --profile  Select a profile defined in profiles/NAME.profile.
  --dry-run  Check prerequisites and simulate without changing files.
  --unlink   Remove only links owned by these packages (no submodule setup needed).
  --help     Show this help.

Existing files are never adopted or overwritten. No downloads are performed.
EOF
}

fail() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

dry_run=false
action=--stow
profile=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --dry-run) dry_run=true ;;
        --unlink) action=--delete ;;
        --profile)
            [ "$#" -ge 2 ] || fail '--profile requires a name (see --help).'
            [ -n "$2" ] || fail '--profile requires a non-empty name.'
            profile=$2
            shift
            ;;
        *) fail "Unknown argument: $1 (see --help)" ;;
    esac
    shift
done

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
cd "$REPO_ROOT"
[ -n "${HOME:-}" ] || fail 'HOME must be set to an existing absolute directory.'
case "$HOME" in
    /*) ;;
    *) fail 'HOME must be an absolute directory.' ;;
esac
[ -d "$HOME" ] || fail "HOME is not a directory: $HOME"
command -v stow >/dev/null 2>&1 || fail 'GNU Stow is required. Install stow using your system package manager.'

# Stow reads both files automatically. Their options may enable adoption or
# overrides, so do not let ambient configuration weaken the safety contract.
for config in "$HOME/.stowrc" "$REPO_ROOT/.stowrc"; do
    if [ -e "$config" ] || [ -L "$config" ]; then
        fail "Stow options file found: $config. Review and temporarily move this file before using the installer; custom adoption/override options are not supported."
    fi
done

# The resolver emits only allowlisted package names, never shell fragments.
if [ -n "$profile" ]; then
    packages=$(sh "$REPO_ROOT/scripts/profile-packages.sh" --profile "$profile") ||
        fail 'Cannot resolve profile; no changes were made.'
else
    packages=$(sh "$REPO_ROOT/scripts/profile-packages.sh") ||
        fail 'Cannot resolve profile; no changes were made.'
fi
set --
while IFS= read -r package; do
    [ -n "$package" ] || continue
    set -- "$@" "$package"
done <<EOF_PACKAGES
$packages
EOF_PACKAGES
[ "$#" -gt 0 ] || fail 'The selected profile has no packages.'
for package do
    [ -d "$REPO_ROOT/$package" ] || fail "Missing package directory: $package"
    if [ "$action" = --stow ] && [ -d "$REPO_ROOT/$package/.config" ] &&
        [ "${XDG_CONFIG_HOME:-$HOME/.config}" != "$HOME/.config" ] &&
        [ "${XDG_CONFIG_HOME:-$HOME/.config}" != "$HOME/.config/" ]; then
        fail 'This Stow layout installs config under HOME/.config, but XDG_CONFIG_HOME selects another location. No changes were made; see docs/profiles.md.'
    fi
done

if [ "$action" = --stow ]; then
    command -v git >/dev/null 2>&1 || fail 'Git is required to check submodules. Install git using your system package manager.'
    submodule_status=$(git -C "$REPO_ROOT" submodule status --recursive -- "$@") ||
        fail 'Cannot inspect submodules. Use a Git checkout of this repository.'
    case "$submodule_status" in
        '') fail 'No submodules found. Use a complete Git checkout of this repository.' ;;
    esac
    if printf '%s\n' "$submodule_status" | grep -q '^[-U]'; then
        printf '%s\n' "$submodule_status" >&2
        printf 'install.sh: Submodules are uninitialized or conflicted. Resolve conflicts, then run:\n  git -C "%s" submodule update --init --recursive\nRetry the installer afterward. This installer never downloads dependencies.\n' "$REPO_ROOT" >&2
        exit 1
    fi
fi

# Simulate the entire selection before making any changes, not one package at
# a time. --stow is idempotent and avoids restow's unnecessary unlink phase.
if [ "$action" = --delete ]; then
    # Stow may sweep dangling links owned by other packages in directories it
    # visits. Refuse this ambiguous case before Stow can schedule any removals.
    for package do
        directories=$(find "$REPO_ROOT/$package" -type d -print) ||
            fail "Cannot inspect package directories: $package"
        while IFS= read -r source_dir; do
            target_dir="$HOME${source_dir#"$REPO_ROOT/$package"}"
            [ -d "$target_dir" ] || continue
            if [ -L "$target_dir" ] && [ "$target_dir" != "$HOME" ]; then
                continue
            fi
            for node in "$target_dir"/.[!.]* "$target_dir"/..?* "$target_dir"/*; do
                if [ -L "$node" ] && [ ! -e "$node" ]; then
                    fail "Unlink refused: dangling link in a target directory: $node. Inspect and repair or explicitly move this link first; Stow may otherwise sweep unselected links. No changes were made."
                fi
            done
        done <<EOF_DIRECTORIES
$directories
EOF_DIRECTORIES
    done
fi
if ! stow --dir="$REPO_ROOT" --target="$HOME" --no-folding --simulate "$action" "$@"; then
    fail 'Stow preflight failed; no changes were made. Back up and move only the reported conflicting paths, then retry (see docs/installer.md).'
fi
if [ "$dry_run" = true ]; then
    printf 'Dry run complete; no changes made.\n'
    exit 0
fi
stow --dir="$REPO_ROOT" --target="$HOME" --no-folding "$action" "$@"

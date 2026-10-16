#!/usr/bin/env sh
set -eu

usage() {
    cat <<'EOF'
Usage: install.sh [--dry-run] [--unlink] [--help]

Link gh gh-copilot nano nvim starship vim zsh into HOME using GNU Stow.
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
for argument do
    case "$argument" in
        --help|-h) usage; exit 0 ;;
        --dry-run) dry_run=true ;;
        --unlink) action=--delete ;;
        *) fail "Unknown argument: $argument (see --help)" ;;
    esac
done

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
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

# Keep package selection in one place so future profiles can reuse the same
# validation, preflight and execution path.
set -- gh gh-copilot nano nvim starship vim zsh
for package do
    [ -d "$REPO_ROOT/$package" ] || fail "Missing package directory: $package"
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
if ! stow --dir="$REPO_ROOT" --target="$HOME" --no-folding --simulate "$action" "$@"; then
    fail 'Stow preflight failed; no changes were made. Back up and move only the reported conflicting paths, then retry (see docs/installer.md).'
fi
if [ "$dry_run" = true ]; then
    printf 'Dry run complete; no changes made.\n'
    exit 0
fi
stow --dir="$REPO_ROOT" --target="$HOME" --no-folding "$action" "$@"

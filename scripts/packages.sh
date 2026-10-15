#!/usr/bin/env bash
# Explicit provisioning: never source OS metadata or execute constructed strings.
# Bash 3.2 (macOS) treats empty arrays as unset under nounset.
set -eo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
profile=dev
mode=dry-run
manager_override=
die() { printf '%s\n' "$*" >&2; exit 1; }
while (($#)); do
    case "$1" in
        --profile) (($# >= 2)) || die 'Missing profile'; profile=$2; shift 2 ;;
        --manager) (($# >= 2)) || die 'Missing manager'; manager_override=$2; shift 2 ;;
        --dry-run) mode=dry-run; shift ;;
        --install) mode=install; shift ;;
        --doctor) mode=doctor; shift ;;
        --list) mode=list; shift ;;
        --help) printf '%s\n' 'Usage: packages.sh [--profile minimal|dev|desktop|personal] [--dry-run|--install|--doctor|--list] [--manager apt|dnf|pacman|brew (preview only)]'; exit 0 ;;
        *) die "Unknown argument: $1" ;;
    esac
done
case "$profile" in minimal|dev|desktop|personal) ;; *) die "Unknown profile: $profile" ;; esac
if [[ $mode == install && ( -n $manager_override || ${PACKAGES_TESTING:-0} == 1 ) ]]; then
    die 'Test fixtures and manager overrides cannot install packages'
fi
os=$(uname -s)
arch=$(uname -m)
release=/etc/os-release
if [[ ${PACKAGES_TESTING:-0} == 1 ]]; then
    os=${PACKAGES_TEST_OS:-$os}
    arch=${PACKAGES_TEST_ARCH:-$arch}
    release=${PACKAGES_TEST_OS_RELEASE:-$release}
fi
case "$arch" in x86_64|aarch64|arm64) ;; *) die "Unsupported architecture: $arch" ;; esac
case "$os" in
    Darwin) manager=brew ;;
    Linux)
        [[ -r $release ]] || die "Cannot read $release"
        id=$(sed -n 's/^ID=//p' "$release" | tr -d '\"\047')
        version=$(sed -n 's/^VERSION_ID=//p' "$release" | tr -d '\"\047')
        case "$id" in
            debian) [[ $version == 13 ]] || die 'Supported Debian release: 13'; manager=apt ;;
            ubuntu) [[ $version =~ ^([0-9]+)\.([0-9]+)$ ]] || die 'Invalid Ubuntu version'
                ((10#${BASH_REMATCH[1]} > 24 || (10#${BASH_REMATCH[1]} == 24 && 10#${BASH_REMATCH[2]} >= 4))) || die 'Ubuntu 24.04+ required'; manager=apt ;;
            fedora) case "$version" in 43|44) ;; *) die 'Supported Fedora releases: 43, 44' ;; esac; manager=dnf ;;
            arch) manager=pacman ;;
            *) die "Unsupported distro: $id (no ID_LIKE fallback)" ;;
        esac ;;
    *) die "Unsupported OS: $os" ;;
esac
if [[ -n $manager_override ]]; then manager=$manager_override; fi
case "$manager" in apt) column=3 ;; dnf) column=4 ;; pacman) column=5 ;; brew) column=6 ;; *) die "Unknown manager: $manager" ;; esac
packages=()
commands=()
while read -r tier command apt dnf pacman brew; do
    [[ -n $tier && $tier != \#* ]] || continue
    [[ $profile != minimal || $tier == minimal ]] || continue
    values=("$tier" "$command" "$apt" "$dnf" "$pacman" "$brew")
    package=${values[$((column - 1))]}
    if [[ $package != - ]]; then packages+=("$package"); fi
    commands+=("$command")
done < "$ROOT/packages/cli.tsv"
if [[ $mode == list ]]; then printf '%s\n' "${packages[@]}"; exit 0; fi
if [[ $mode == doctor ]]; then
    failed=0
    for command in "${commands[@]}"; do
        case "$command" in
            certificates|venv) continue ;;
            starship) command -v starship >/dev/null 2>&1 || printf '%s\n' 'Optional: starship missing; see docs/dependencies.md'; continue ;;
            fd) command -v fdfind >/dev/null 2>&1 && continue ;;
        esac
        if ! command -v "$command" >/dev/null 2>&1; then printf 'Missing: %s\n' "$command"; failed=1; fi
    done
    if [[ $profile != minimal ]] && command -v nvim >/dev/null 2>&1; then
        version=$(nvim --version | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [[ ! $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || ! ((10#${BASH_REMATCH[1]} > 0 || 10#${BASH_REMATCH[2]} > 11 || (10#${BASH_REMATCH[2]} == 11 && 10#${BASH_REMATCH[3]} >= 3))); then
            printf '%s\n' 'Neovim >=0.11.3 required; install a verified user-level release (docs/dependencies.md), then re-run --doctor.'
            failed=1
        fi
    fi
    exit "$failed"
fi
case "$manager" in
    apt) update=(apt-get update); install=(apt-get install -y --no-install-recommends) ;;
    dnf) update=(); install=(dnf install -y) ;;
    pacman) update=(); install=(pacman -Syu --needed --noconfirm) ;;
    brew) update=(); install=(brew install) ;;
esac
run() {
    if [[ $mode == dry-run ]]; then printf 'Would run:'; printf ' %q' "$@"; printf '\n'; else "$@"; fi
}
prefix=()
if [[ $manager != brew && $(id -u) != 0 ]]; then prefix=(sudo); fi
if [[ $mode == install ]]; then
    binary=${install[0]}
    command -v "$binary" >/dev/null 2>&1 || die "Install $binary first; see docs/dependencies.md"
    if ((${#prefix[@]})); then command -v sudo >/dev/null 2>&1 || die 'Run as root or install sudo'; fi
fi
if ((${#update[@]})); then run "${prefix[@]}" "${update[@]}"; fi
run "${prefix[@]}" "${install[@]}" "${packages[@]}"
if [[ $profile == desktop || $profile == personal ]]; then
    if [[ $os == Darwin && $manager == brew ]]; then
        run brew bundle --file="$ROOT/packages/Brewfile.desktop"
        if [[ $profile == personal ]]; then run brew bundle --file="$ROOT/packages/Brewfile.personal"; fi
    else
        printf '%s\n' 'Desktop/personal application bundles are macOS-only; CLI dev packages selected.'
    fi
fi
if [[ $profile != minimal ]]; then
    printf '%s\n' 'Starship is optional (not installed by apt/dnf); verify Neovim >=0.11.3 with --doctor. See docs/dependencies.md.'
fi

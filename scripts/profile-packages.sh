#!/bin/sh
# Resolve trusted, declarative Stow profiles. No profile file is shell-sourced.
set -eu

usage() {
    printf '%s\n' 'Usage: sh scripts/profile-packages.sh [--profile minimal|dev|desktop|personal]'
}

profile=dev
case $# in
    0) ;;
    1)
        case $1 in
            -h|--help) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    2)
        if [ "$1" != --profile ]; then
            usage >&2
            exit 2
        fi
        profile=$2
        ;;
    *) usage >&2; exit 2 ;;
esac

case $profile in
    minimal|dev|desktop|personal) ;;
    *) printf 'Unknown profile: %s\n' "$profile" >&2; exit 2 ;;
esac

root=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
for name in minimal dev desktop personal; do
    if [ ! -r "$root/profiles/$name.profile" ]; then
        printf 'Missing profile definition: %s\n' "$name" >&2
        exit 2
    fi
done

awk -v selected="$profile" '
function fail(message) {
    print "Invalid profile definition: " message | "cat >&2"
    close("cat >&2")
    failed = 1
    exit 2
}
function visit(name,    i, parent) {
    if (state[name] == 1) fail("inheritance cycle at " name)
    if (state[name] == 2) return
    state[name] = 1
    for (i = 1; i <= parent_count[name]; i++) {
        parent = parents[name, i]
        visit(parent)
    }
    for (i = 1; i <= package_count[name]; i++) {
        included[packages[name, i]] = 1
    }
    state[name] = 2
}
BEGIN {
    count = split("gh gh-copilot nano nvim starship vim zsh", ordered, " ")
    for (i = 1; i <= count; i++) allowed[ordered[i]] = 1
    split("minimal dev desktop personal", names, " ")
    for (i = 1; i <= 4; i++) known[names[i]] = 1
}
FNR == 1 {
    name = FILENAME
    sub(/^.*\//, "", name)
    sub(/\.profile$/, "", name)
}
/^[[:space:]]*(#|$)/ { next }
{
    if (NF != 2) fail(name ": expected exactly a directive and a value")
    if ($1 == "extends") {
        if (!($2 in known)) fail(name ": unknown parent " $2)
        parents[name, ++parent_count[name]] = $2
    } else if ($1 == "package") {
        if (!($2 in allowed)) fail(name ": unsupported Stow package " $2)
        packages[name, ++package_count[name]] = $2
    } else {
        fail(name ": unknown directive " $1)
    }
}
END {
    if (failed) exit 2
    visit(selected)
    for (i = 1; i <= count; i++) {
        if (ordered[i] in included) print ordered[i]
    }
}
' "$root/profiles/minimal.profile" "$root/profiles/dev.profile" \
    "$root/profiles/desktop.profile" "$root/profiles/personal.profile"

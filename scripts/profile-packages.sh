#!/bin/sh
# Resolve trusted, declarative profile selections. Profile files are never sourced.
set -eu

root=$(CDPATH='' cd -P "$(dirname "$0")/.." && pwd)
kind=stow-package
profile=
usage() {
    printf '%s\n' 'Usage: sh scripts/profile-packages.sh [--profile NAME] [--kind stow-package|cli-group|macos-bundle]'
}
while [ "$#" -gt 0 ]; do
    case $1 in
        --profile)
            [ "$#" -ge 2 ] || { usage >&2; exit 2; }
            [ -n "$2" ] || { printf '%s\n' 'Unknown profile: ' >&2; exit 2; }
            profile=$2
            shift 2
            ;;
        --kind)
            [ "$#" -ge 2 ] || { usage >&2; exit 2; }
            kind=$2
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
case $kind in stow-package|cli-group|macos-bundle) ;; *) usage >&2; exit 2 ;; esac

default=$(cat "$root/profiles/default")
case $default in ''|*[!A-Za-z0-9_-]*) printf '%s\n' 'Invalid default profile' >&2; exit 2 ;; esac
[ -n "$profile" ] || profile=$default
case $profile in *[!A-Za-z0-9_-]*|'') printf 'Unknown profile: %s\n' "$profile" >&2; exit 2 ;; esac

set -- "$root"/profiles/*.profile
profile_names=
for file do
    [ -f "$file" ] || { printf '%s\n' 'No profile definitions found' >&2; exit 2; }
    name=${file##*/}
    name=${name%.profile}
    case $name in ''|*[!A-Za-z0-9_-]*) printf 'Invalid profile filename: %s\n' "$file" >&2; exit 2 ;; esac
    profile_names="$profile_names $name"
done
case " $profile_names " in *" $profile "*) ;; *) printf 'Unknown profile: %s\n' "$profile" >&2; exit 2 ;; esac

allowed_packages=$(tr '\n' ' ' < "$root/profiles/packages")
allowed_groups=$(awk '!/^#/ && NF { print $1 }' "$root/packages/cli.tsv" | sort -u | tr '\n' ' ')
allowed_bundles=
set -- "$root"/packages/Brewfile.*
for file do
    [ -f "$file" ] || continue
    name=${file##*/Brewfile.}
    allowed_bundles="$allowed_bundles $name"
done

# Metadata and all allowlists are passed as data. This keeps profile names and
# selection policy out of executable case statements as profiles are added.
# shellcheck disable=SC2086
awk -v selected="$profile" -v kind="$kind" \
    -v profile_names="$profile_names" -v allowed_packages="$allowed_packages" \
    -v allowed_groups="$allowed_groups" -v allowed_bundles="$allowed_bundles" '
function fail(message) {
    print "Invalid profile definition: " message | "cat >&2"
    close("cat >&2")
    failed = 1
    exit 2
}
function visit(name,    i, parent, item, type) {
    if (state[name] == 1) fail("inheritance cycle at " name)
    if (state[name] == 2) return
    state[name] = 1
    for (i = 1; i <= parent_count[name]; i++) visit(parents[name, i])
    for (i = 1; i <= selection_count[name]; i++) {
        type = selections[name, i, 1]
        item = selections[name, i, 2]
        if (type == kind) included[item] = 1
    }
    state[name] = 2
}
BEGIN {
    count = split(profile_names, names, " ")
    for (i = 1; i <= count; i++) if (names[i] != "") known[names[i]] = 1
    count = split(allowed_packages, names, " ")
    for (i = 1; i <= count; i++) if (names[i] != "") packages[names[i]] = 1
    count = split(allowed_groups, names, " ")
    for (i = 1; i <= count; i++) if (names[i] != "") groups[names[i]] = 1
    count = split(allowed_bundles, names, " ")
    for (i = 1; i <= count; i++) if (names[i] != "") bundles[names[i]] = 1
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
        next
    }
    type = $1 == "package" ? "stow-package" : $1
    if (type != "stow-package" && type != "cli-group" && type != "macos-bundle")
        fail(name ": unknown directive " $1)
    if ((type == "stow-package" && !($2 in packages)) ||
        (type == "cli-group" && !($2 in groups)) ||
        (type == "macos-bundle" && !($2 in bundles)))
        fail(name ": unsupported " type " " $2)
    i = ++selection_count[name]
    selections[name, i, 1] = type
    selections[name, i, 2] = $2
}
END {
    if (failed) exit 2
    visit(selected)
    for (item in included) print item | "sort"
    close("sort")
}
' "$root"/profiles/*.profile

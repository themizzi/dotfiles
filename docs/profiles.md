# Profiles

Profiles are declarative selections resolved by `scripts/profile-packages.sh`.
The resolver is independent of the installer and does not install software or
change files:

```sh
sh scripts/profile-packages.sh --profile dev
sh scripts/profile-packages.sh --profile desktop --kind macos-bundle
```

Omitting `--profile` uses the single value in `profiles/default`. Profile names
are discovered from `profiles/*.profile`; adding or removing a profile does not
require editing resolver or installer code. Output is sorted, stable, and
deduplicated. Errors print to stderr and return a nonzero status.

| Profile | Inherits | Stow packages | CLI groups | macOS bundles |
| --- | --- | --- | --- | --- |
| `minimal` | — | `vim`, `zsh` | `base` | — |
| `dev` (default) | `minimal` | `gh`, `nano`, `nvim`, `starship`, `vim`, `zsh` | `base`, `development` | — |
| `desktop` | `dev` | `gh`, `nano`, `nvim`, `starship`, `vim`, `zsh` | `base`, `development` | `desktop` |
| `personal` | `dev` | `gh`, `gh-copilot`, `nano`, `nvim`, `starship`, `vim`, `zsh` | `base`, `development` | `desktop`, `personal` |

`minimal` keeps the minimal Vim/Zsh setup and CLI baseline. `dev` adds general
development tools. `desktop` and `personal` add their declared macOS application
bundles; Linux reports those bundles as macOS-only. `personal` opts in to
existing Copilot configuration and applications; it does not authenticate GitHub
or enable a subscription.

The existing Stow tree installs application configuration under `~/.config`. For
profiles containing such packages, linking refuses a non-default
`XDG_CONFIG_HOME` instead of silently installing files the applications will not
read. Relocating the Stow config tree is not implemented here. The shell itself
preserves custom XDG values, and `minimal` can be used with those values because
its Vim/Zsh packages do not contain `.config` files. Unlink still addresses the
standard paths where the installer previously created links.

## Definitions and safety

`profiles/NAME.profile` is data, never executable shell. Blank lines and
whole-line `#` comments are allowed. Each other line contains exactly two
fields, one of:

```text
extends PROFILE
package STOW_PACKAGE
cli-group GROUP
macos-bundle BUNDLE
```

Inheritance is deduplicated; cycles fail before output. All profile files are
validated, including profiles not selected. Profile names come from filenames.
Allowed Stow packages are listed in `profiles/packages`; CLI groups come from
the first column of `packages/cli.tsv`; macOS bundle names come from matching
`packages/Brewfile.NAME` files. These data sources keep profile selection out of
shell `case` statements and avoid maintaining parallel allowlists in code.

## Installer and provisioning integration

Select the installer profile with:

```sh
sh install.sh --profile NAME
```

The installer checks only submodules belonging to selected Stow packages.
Omitting `--profile` uses `profiles/default`. Unlinking also uses the selected
profile and does not automatically remove links from previously installed
profiles. Explicitly unlink the previous selection before switching profiles.

For provisioning, `scripts/packages.sh` asks the same resolver for the selected
profile's CLI groups and macOS bundles. The CLI manifest maps groups to native
package names; Stow package names are never treated as system packages. Add a
CLI dependency to a group in the manifest and select that group in a profile.
Add a macOS bundle by providing its `Brewfile.NAME` and referencing `NAME` in a
profile.

## Tests

Profile resolution and installer integration are covered by the pinned Bats
suite. Resolver tests use disposable profile directories, including adding a
profile file without changing resolver code. Run `just test --filter 'profile'`;
the suite does not run Stow or modify the user home directory.

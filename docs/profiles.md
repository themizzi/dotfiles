# Profiles

Only `minimal` and `personal` are selectable. The resolver also selects CLI
dependency groups and macOS bundles from the same declarative profile files:

```sh
sh scripts/profile-packages.sh --profile personal
sh scripts/profile-packages.sh --profile personal --kind cli-group
sh scripts/profile-packages.sh --profile personal --kind macos-bundle
```

Omitting `--profile` uses `profiles/default` (`personal`). Names are discovered
from `profiles/*.profile`; adding or removing a profile needs no resolver or
installer code changes. Output is sorted, stable, and deduplicated.

| Profile | Inherits | Stow packages | CLI groups | macOS bundles |
| --- | --- | --- | --- | --- |
| `minimal` | — | `vim`, `zsh` | `base` | — |
| `personal` (default) | `minimal` | `gh`, `gh-copilot`, `nano`, `nvim`, `starship`, `vim`, `zsh` | `base`, `development` | `desktop`, `personal` |

`minimal` is the shell/editor baseline. `personal` includes the full CLI and
configuration selections plus both explicit macOS application bundles. Linux
reports application bundles as macOS-only. Copilot configuration does not
authenticate GitHub or enable a subscription.

Profiles are declarative data, never executable shell. Each non-comment line in
`profiles/NAME.profile` contains exactly two fields:

```text
extends PROFILE
package STOW_PACKAGE
cli-group GROUP
macos-bundle BUNDLE
```

Inheritance is deduplicated; cycles fail before output. All profile files are
validated, including those not selected. Allowed Stow packages are listed in
`profiles/packages`; CLI groups come from the first column of `packages/cli.tsv`;
macOS bundle names come from `packages/Brewfile.NAME` files. These data sources
avoid parallel profile-name and selection lists in executable code.

The existing Stow tree installs application configuration under `~/.config`. For
profiles containing such packages, linking refuses a non-default
`XDG_CONFIG_HOME` instead of silently installing files the applications will not
read. `minimal` can be used with custom XDG values because its packages do not
contain `.config` files.

The installer and package provisioner both use this resolver. Unlinking uses the
selected profile and does not automatically remove links from another previously
installed profile. Explicitly unlink the previous selection before switching.
Provisioning uses CLI groups rather than treating Stow package names as system
packages.

Profile resolution and installer integration use the pinned Bats suite. Tests
cover dynamic profile discovery, defaults, invalid metadata, and inheritance:

```sh
just test --filter 'profile'
```

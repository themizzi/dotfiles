# Profiles

Profiles select existing Stow packages explicitly. The resolver is independent
of the installer and does not install software or change any files:

```sh
sh scripts/profile-packages.sh --profile dev
```

Omitting `--profile` selects `dev`. Success prints one package per line to
stdout, in the stable order below, without duplicates. Errors print to stderr,
produce no package list, and return a nonzero status. Run it from any directory;
definitions are located relative to the script, not the current directory.

| Profile | Inherits | Exact Stow package list (output order) |
| --- | --- | --- |
| `minimal` | — | `vim`, `zsh` |
| `dev` (default) | `minimal` | `gh`, `nano`, `nvim`, `starship`, `vim`, `zsh` |
| `desktop` | `dev` | `gh`, `nano`, `nvim`, `starship`, `vim`, `zsh` |
| `personal` | `dev` | `gh`, `gh-copilot`, `nano`, `nvim`, `starship`, `vim`, `zsh` |

`minimal` keeps the existing minimal Vim configuration and avoids requiring
Starship. `dev` retains the general development configurations, including nano.
`personal` explicitly opts in to the existing Copilot configuration; it does not
authenticate GitHub or enable a subscription. No existing configurations are
removed. The old installer selected seven packages including `gh-copilot`;
`dev` intentionally selects six because Copilot is now opt-in. `personal`
reproduces that former seven-package selection.

The existing Stow tree installs application configuration under `~/.config`.
For profiles containing such packages, linking refuses a non-default
`XDG_CONFIG_HOME` instead of silently installing files the applications will not
read. Relocating the Stow config tree is not implemented here. The shell itself
preserves custom XDG values, and `minimal` can be used with those values because
its Vim/Zsh packages do not contain `.config` files. Unlink still addresses the
standard paths where the installer previously created links.

## Definitions and safety

`profiles/NAME.profile` is data, never executable shell. Blank lines and
whole-line `#` comments are allowed. Each other line must contain exactly
`extends NAME` or `package PACKAGE`. Multiple inheritance is supported;
inherited and repeated packages appear only once. Cycles in the selected
inheritance graph fail before any list is printed. Unknown profiles, parents,
directives, and packages are errors. The resolver validates syntax and names in
all four files, including profiles not selected.

Names are limited to `minimal`, `dev`, `desktop`, and `personal`; package names
are limited to `gh`, `gh-copilot`, `nano`, `nvim`, `starship`, `vim`, and `zsh`.
Neither paths nor shell fragments can be supplied as a profile. Adding a real
Stow package requires deliberately updating the resolver allowlist as well as
the definitions. Output order is the allowlist order, not inheritance order.

## Installer and provisioning integration

Select the installer profile with:

```sh
sh install.sh --profile NAME
```

The installer checks only submodules belonging to selected packages. Omitting
`--profile` selects `dev`; use `--profile personal` for the old seven-package
selection. Unlinking also uses the selected profile and does not automatically
remove links from previously installed profiles. To switch profiles, explicitly
unlink the previous selection before linking the new one.

The resolver API for the installer is:

```sh
sh "$repository/scripts/profile-packages.sh" --profile "$profile"
```

Check its exit status before invoking Stow. Each output line is one validated
Stow package argument; never `eval` the output. The default is `dev`.

The dependency-management PR adds `sh scripts/packages.sh --profile NAME --dry-run`.
Provisioning accepts the same four profile names, but maintains its own
external-package mapping: Stow directories are not system package names. For
example, `minimal` can provision the shell/editor and Stow, `dev` development
tools and language runtimes, and `desktop` additional platform-appropriate GUI
applications. `personal` may add optional personal tools. `desktop` deliberately
has no fictitious desktop Stow package. Provisioning may install more tools
than have symlink configurations; it must not feed those names into Stow.

## Tests

```sh
python3 -m unittest discover -s test -p test_profiles.py
```

Tests require only Python 3, a POSIX shell, and awk, and never run Stow or modify
the user home directory.

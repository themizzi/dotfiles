# G915 macOS-style keyboard

Toshy starts automatically. Physical keys on the G915:

| Key | Role |
| --- | --- |
| Left Alt | Command |
| Left Windows | Option |
| Left Ctrl | Mac Control (including terminal interrupt) |
| Right Ctrl | Dedicated Hyprland modifier |

## Daily shortcuts

- Alt+C/V/X/Z/A/S: Command-style copy, paste, cut, undo, select all, save.
- Alt+Left/Right: beginning/end of line; add Shift to select.
- Windows+Left/Right: previous/next word; add Shift to select.
- Windows+Backspace: delete the preceding word.
- Windows+E, release, then E: acute-accented e using the native Macintosh layout.
- Alt+Space: existing Hyprshell overview and launcher.
- Alt+Tab: existing Hyprshell window switcher, not macOS application grouping.
- Ctrl+Alt+F: toggle fullscreen.
- Ctrl+Alt+Q: lock screen.
- Alt+Shift+3: full-screen screenshot saved under ~/Pictures/Screenshots.
- Alt+Shift+4: select an area for a screenshot; Escape cancels.
- Add left Ctrl to screenshot shortcuts to copy instead of saving.
- Alt+H/M: park the focused window in the mac-hidden special workspace.
  This hides one window, not every window belonging to an application.

## Hyprland controls

**Left Ctrl + Windows + Enter** opens a new Kitty terminal, from GUI apps
or another terminal.

**Left Ctrl + Windows + arrows** focuses the neighboring window in that
direction, in both GUI apps and terminals. Windows+arrows and Alt+arrows
retain their text-navigation behavior.

**Left Ctrl + Windows + A/D** moves the focused window to the left/right
monitor. This works in GUI apps and terminals while Toshy is running.
At the left/right edge, the shortcut does nothing rather than showing an error.

Hold **right Ctrl + Windows** (the window-management chord), then:

- Enter: terminal.
- Arrows: focus another window.
- Shift+Left/Right: move the window between monitors.
- 1–0: workspace; add Shift to move the window there.
- Q: close window; F: fullscreen; V: toggle floating.
- H: show/hide parked windows. To restore a parked window to a normal
  workspace, focus it and use the chord + Shift + workspace number.
- L: lock; B: toggle Waybar; Shift+S: area screenshot to clipboard.
- Left/right mouse drag: move/resize a window.

## Disable or recover

- **Pause**: stop Toshy. **Scroll Lock**: start it again.
- Alternatively: `~/.local/bin/toshy-services-stop` or
  `~/.local/bin/toshy-services-start`.
- With Toshy stopped, left Windows + left Alt is the Hyprland modifier chord.
- Toshy's tray menu provides preferences and service controls.

Configuration:

- `~/.config/toshy/toshy_config.py`: remapping; customizations are inside
  upgrade-preserved slice markers.
- `~/.config/hypr/hyprland.lua`: native Macintosh character layout, compositor
  shortcuts, and startup.
- `~/.local/bin/macos-screenshot`: screenshot helper.
- Original configurations: `~/.config/toshy/backups/20261015-150036-before-macos-setup/`.

Remote desktop/VM applications retain Toshy's default remapping exclusions.
The native XKB Macintosh symbol layout is a close approximation, not an exact
implementation of every macOS character or application behavior.

# Omarchy Bar · Caelestia Style

**English** | [中文](README.cn.md)

A custom bar saved from the `~/.config/omarchy/plugins/sym.bar` currently in use on this machine, built on Omarchy's built-in Quickshell bar. It is not a standalone shell and not an official Caelestia project; it depends on the installed Omarchy Shell, its shared QML modules, and built-in components.

## Current appearance

- A left-edge bar, joined to the 6px same-color outer frame along the top, right, and bottom edges.
- The desktop opening uses 22px inverted (concave) corner radii; the decoration layer is click-through and never takes keyboard focus.
- The frame hides together with the bar in hidden or transparent mode, and is redrawn with theme colors and screen size.
- Paired with 12px Hyprland window rounding; visible gaps around windows and between windows are both 8px.
- The frame is only enabled in the left layout; other directions keep the bar's base behavior.

## Files

- `plugin/`: complete code of the currently running plugin, keeping the plugin ID `sym.bar` and the upstream author information.
- `config/bar.json`: current bar configuration and component layout; merge its `bar` field.
- `config/looknfeel.lua`: Hyprland look-and-feel snippet matching the frame.
- `docs/upstream-bar.md`: upstream bar documentation kept from the clone, describing the default implementation; some paths and default behaviors do not apply to this project.

## Install or sync changes

Back up the target machine's existing `~/.config/omarchy/shell.json`, `~/.config/hypr/looknfeel.lua`, and `~/.config/omarchy/plugins/sym.bar/` first.

1. Copy the contents of `plugin/` into `~/.config/omarchy/plugins/sym.bar/`.
2. Merge the `bar` field of `config/bar.json` into `~/.config/omarchy/shell.json`, keeping the other settings in that file. You can keep your own component layout and adopt only this project's style fields and `id`.
3. Merge `config/looknfeel.lua` into `~/.config/hypr/looknfeel.lua`, making sure no later configuration overrides these values.
4. Run `omarchy restart shell`, then `hyprctl reload` and `hyprctl configerrors`.

This repository is a standalone copy; after editing it here you must copy the files to the user plugin directory for the changes to take effect. To roll back, restore the backups and restart the shell and reload Hyprland.

## Style parameters

Set these in the `bar` object of `shell.json`:

| Field | Current value | Purpose |
| --- | --- | --- |
| `id` | `sym.bar` | Select the custom plugin |
| `position` | `left` | Bar on the left |
| `outerMargin` | `0` | Bar flush with the screen edge |
| `cornerRadius` | `0` | Bar body stays square |
| `frameWidth` | `6` | Thickness of the desktop frame |
| `frameRadius` | `22` | Corner radius of the desktop opening |

Hyprland's `gaps_out` is 14 on the top, right, and bottom edges and 8 on the left; the first three edges include the 6px decoration frame. `gaps_in=4` gives a total of 8px between adjacent windows. If you change the frame thickness, adjust `gaps_out` on those three edges accordingly.

## Implementation and verification

`Bar.qml` adds a separate transparent desktop decoration layer, draws the frame with a Canvas, and cuts out rounded openings; an empty input region makes it click-through. The clone also fixes an initialization compatibility issue with the host's lazily injected properties and the outer-margin calculation for bar drag coordinates.

Loading, screenshot appearance, hide/restore, and the audio popup have been verified on this machine; multi-monitor and real mouse dragging are not fully verified yet. The code snapshot was taken on 2026-09-08; check shared-module compatibility after upgrading Omarchy.

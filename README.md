# Mouse Settings

An Omarchy bar plugin for mouse acceleration and pointer/scroll speed — the
kind of panel Windows and macOS ship for mouse settings, built for Hyprland.

- **Mouse acceleration** — on/off switch. Maps to Hyprland's `accel_profile`
  (`adaptive` / `flat`).
- **Pointer speed** — slider, matches Hyprland's `sensitivity` range (-1 to 1).
- **Scroll speed** — slider, matches Hyprland's `scroll_factor` range (0 to 2).
- **Reset to defaults** — one click back to `adaptive` / `0` / `1`.
- **Advanced** (gear icon) — customize each slider's min, max, and step size.
  Persisted on the widget's own `shell.json` entry via `omarchy bar set`, so
  it survives plugin updates.

Changes apply immediately: the plugin edits `~/.config/hypr/input.lua` and
reloads Hyprland. It edits only the `sensitivity`, `accel_profile`, and
`scroll_factor` keys inside your existing `hl.config({ input = {...} })`
block — everything else in that file (keyboard layout, touchpad settings,
your comments) is left untouched. A dated backup of `input.lua` is taken
before the first change of the day.

## Install

```bash
omarchy plugin add https://github.com/tseitz/omarchy-mouse-settings.git --enable
```

## Requirements

Hyprland's Lua config, which ships with Omarchy by default. `input.lua` must
already have an `hl.config({ input = {...} })` block — every Omarchy install
has one out of the box.

## Development

```bash
node --test test/
```

`lib/Model.js` owns the `input.lua` text parsing/editing (pure functions,
covered by `test/`); `Panel.qml` and `BarWidget.qml` own the UI and wiring
to `hyprctl reload`.

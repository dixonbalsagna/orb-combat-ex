# a1-window-row: the Window row, Full screen or Windowed (A-PERF-08; UI & UX, 2026-11-14; park, not landed)

The UI half of Rendering's `docs/rendering/pending/window-display` (the desktop build opens full screen; the host applies this row). **Land with or after that park, after GW1a**; the stack before it is `a1-world-menu` (apply last).

`window-row.patch` (`patch -p1` / `git apply`; dry-run clean on the stack through `a1-world-menu`, and the whole stack equals the tree the gate ran on): `ui/data/options.json` (`window_mode`), `ui/data/settings.json` (the Display group's first row and the two words), `ui/hud/ui_hud.gd` (the option's default in `opts`), `ui/widgets/ui_settings.gd` (the row is not listed on the web), the regenerated pseudo-locale and `docs/ui/strings.md`, `ui/tools/hud_check.gd` (`_window_row_rules`).

- **The row:** "Window" in Settings, Display group, **Full screen** (default) or **Windowed**, stepped with Left and Right or A like every choice, saved with the other options.
- **Not on the web:** the browser has its own full screen, so `UiSettings.rows()` leaves the row out there (`WEB_HIDDEN`; the option itself still exists and keeps its default).
- **The host:** nothing to grant. `opts["window_mode"]` is in the HUD's options from the start and a change goes out through `option_changed("window_mode", value)`, which is what Rendering's `_apply_display()` listens for (`opts.get("window_mode", "fullscreen")`); a value that is not a choice becomes Full screen (`UiData.clamp_option`).
- **Words for Orb:** the row "Window", the two choices "Full screen" and "Windowed", and its help line: "Full screen fills the screen. Windowed opens a window you can move and resize. The change takes effect at once. Not shown in the browser, which has its own full screen."
- **Tests:** the option's default and choices; Settings lists it in Display with the two words; listed on a desktop build and not in the browser; in the HUD the row steps between the two and tells the host each change; a value that is not a choice becomes the default.

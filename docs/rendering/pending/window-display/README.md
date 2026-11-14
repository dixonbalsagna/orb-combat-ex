# The game's window: full screen on a desktop, a Window row to change it (A-PERF-08)

Parked by Rendering on 2026-11-14 for sprint A1. The game set no window: the project file had no display section, so a desktop build opened Godot's default 1152 by 648 window, and the Steam Deck's 1280 by 800 screen wasn't filled (`docs/tools/steam-deck.md`). `window_display.diff` (sha1 SHA, LINES lines, cut on main BASE) changes two files:

- **`project.godot` (a grant):** a `[display]` section:
  - `window/size/mode=3` starts a desktop build full screen (borderless, at the screen's own size), so any screen is filled, a 1280 by 800 one included;
  - `window/size/mode.web=0` keeps the web build as it is (the page owns the canvas; a browser refuses full screen without a press), the same feature-tag form as the file's `general/default_playback_type.web`.
- **`render/core/main.gd` (Rendering's):** `_apply_display()` applies UI's Window row (`window_mode`: `"fullscreen"`, the default, or `"windowed"`):
  - a saved "windowed" makes a window at the start, and a change on the Settings screen does so at once;
  - "windowed" opens 1280 by 720, centred, within nine tenths of the screen's usable area; a window the player has already sized or maximised is left alone;
  - it does nothing on the web, headless, in a tool, under the capture hook, a bench or a scripted run, or when the command line names one of Godot's own window flags (`--windowed`, `--fullscreen`, `--maximized`, `--resolution`), so a tester can still ask for a window.

## The stated choices (acceptance 6)

| | Choice |
|---|---|
| **Window mode and size** | Full screen at the screen's own size on Windows and Linux (and macOS). Windowed by the row: 1280 by 720. |
| **Vertical sync** | A fixed choice: on (Godot's default, written in the file's comment). Off only for `--bench` and `--novsync`, as today. |
| **Frame cap** | A fixed choice: none. Sync caps the frame rate at the screen's rate; the bench needs uncapped frames. On the Steam Deck, its own frame limiter is the player's. |
| **What the player changes** | One row, Window: Full screen or Windowed. UI builds it (below). |

What stays the same:
- the base size (1152 by 648), which is what every headless check and tool draws at;
- the stretch mode (disabled), so the view takes the window's size, as the web canvas does today, and the HUD lays itself out per size as it already does.

## Proof

On main BASE with this park (`docs/rendering/runs/BASE/window-display.txt`): PROOF.

The window itself can't be seen headless, and Godot runs here are headless only. The first desktop build (A-TOOLS-01) is the check: started with no arguments, it should open full screen; with `--windowed` it should open a window; the Window row should switch between the two. Whether the HUD and the split hold at 16:10 is UI's and Camera's to look at (steam-deck.md).

## Owed

- **UI's row** (`ui/data/settings.json`, `ui/hud/ui_hud.gd`'s option defaults):
  - `window_mode` in the Display group: "Full screen" or "Windowed", default `"fullscreen"`, saved like the others, and not listed on the web (the browser has its own full screen);
  - main.gd reads it through `option_changed` and `opts.get("window_mode", "fullscreen")`, so this park works before the row lands, and the row works the day it does.
- **The full flash set (RL-128):** a change to `project.godot` runs it. It should change nothing, since the web build's window is untouched and headless runs ignore the window mode. The EP plans it to run once: with another project-file change in the same landing if there is one.

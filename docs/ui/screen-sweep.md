# The screen sweep (A-UI-09; UI & UX, 2026-11-13; sprint A1; park `a1-screen-sweep`, not landed)

A tool that takes a still of every menu and HUD state at one screen size (1280 by 800, the Steam Deck's, by default) and lists the smallest text on each. It closes A-UI-09's tool and its first set of stills; clipped or small text is expected to be listed, not fixed, in A1.

```
node ui/tools/sweep.mjs --dir <the demo's web export> --out <folder> [--godot <godot exe> --tree <project folder>] [--size 1280x800] [--floor 9] [--aim 12] [--skip-stills] [--only id,id]
```

- **The text half** is `ui/tools/screen_sweep.gd`, run headless (one Godot process, at most): every state is drawn with every line's size and rectangle kept (`UiText.boxing`) and printed as `SWEEP {json}`. The states: the start menu's list of modes (and as opened from a match), the setup for one player and for two, Quit's question, the single start card; the pause menu, the LAN pause, the new-match question, Quit's question, the match-over card (and with a saved file); Settings on the Rail and the old card; the match HUD in each of the five mock scenarios; How to play (and its About page), the feedback panel, the control remap, and the first-run notice.
- **The picture half** is one still a state through `tools/machine/capture.mjs` (Tools' launcher: one capture at a time, a time limit, below-normal priority), the page being the demo's web export with the state's query (`?rail&modes&menu&mpick=solo`, `?scenario=hero_vs_proud`, ...). The queries are in `screen_sweep.gd`, beside the states, so a new state is one line there.
- **The table** is `<out>/sweep.md` and `sweep.json`: a row a state with its still, the number of lines, the smallest text's size and the line it is, how many lines went off the screen, and a verdict: **FAIL** under the floor (9 px), **aim** under 12 px, else ok.
- Needs the demo's web export (the project's main scene set to `res://ui/demo/hud_demo.tscn`, `--export-release "Web"`) for the stills; `--skip-stills` runs the text half alone.

## What it covers and what it does not

It measures **the UI's own text** (everything drawn through `UiText`, so it is the HUD, the cards and the menus), at the draw-time size. Text drawn by other code (the world's labels, a window title, the demo's debug line) is not in it. The smallest UI text is the UI's text floor (14 px) on every state at 1280 by 800 in the first set: no state is under the 9 px floor or the 12 px aim, and none has a line off the screen. Where the first real-game stills come from is Tools' build (the sweep points at any web export of the demo or of the game that takes the same query).

First set: `docs/ui/runs/<sha>/screen-sweep/` (`sweep.md`, `sweep.json`, one still per state).

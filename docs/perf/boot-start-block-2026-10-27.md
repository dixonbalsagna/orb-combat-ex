# What is in the start block, and the full boot, on main 3d276d57 (2026-10-27)

Owner: Performance and Platform, for the EP. A scratch export of 3d276d57 (all four Android boot pieces: Audio's warm-async 3, Simulation's stepped start, Animation's incremental bake, Rendering's boot park). Marks from `hook-bootprof3.mjs` (an autoload that marks the engine start and loads the entry scripts one by one; main._ready cut into parts; the boot loop) and the probe's page-side marks (wasm compile). Same freeze-probe as before (mobile emulation, Android UA, 915 by 412 at 2.625, Tools' launcher, one capture at a time, below normal priority, quiet check before each run). Runs: owner split 2 per cell (x1, x4), boot marks 2 per cell, crumbs 1 per cell. One x4 run (a busy machine, 53 s to playable) is left out as invalid. The page is served from this PC, so no download time. x4 is an old laptop; a phone is slower (x6 not re-run).

## The start block (page start to the first frame), seconds

| Part | x1 | x4 | Owner |
|---|---|---|---|
| Wasm download and compile (39.5 MB) | 0.13 | 0.3 | engine (Tools: page) |
| **Engine init**, wasm up to the first script (settings, servers, graphics context, pck mount of 8.3 MB) | **1.9** | **3.2** | Godot; export config (Performance) |
| **Script load: SimHost's graph** (sim core, director, world, fx: 211 scripts, 70k lines) | **1.2** | **6.4** | Simulation |
| Script load: ui_hud.tscn (58 scripts) | 0.25 | 1.4 | UI |
| Script load: planet view, pane world, fighter view, animation, split view, vfx look, boot | 0.2 | 2.0 | Rendering, Animation, VFX, Camera |
| Script load: main.tscn itself (the rest of main's graph) | 0.18 | 1.1 | Rendering |
| `main._ready`: pane build 0.12 / 0.38, HUD added 0.05 / 0.17, audio bank first slice 0.13 / 0.14 (by design, 120 ms), start_match 0.02 / 0.09 | 0.33 | 0.85 | Rendering, UI, Audio, Simulation |
| **Longest main-thread block** (start to ready_begin) | **4.4** | **15.5** | |

- **The script load is the block**: 1.9 s of 4.4 at x1 and 10.9 s of 15.5 at x4 (70%), and **SimHost's graph alone is 6.4 s at x4**. It is parse, analyse and compile of about 500 scripts (185,000 lines) in wasm; the export already uses compressed binary tokens (`script_export_mode=2`), so this is not text parsing. Attribution is by first need: a script that two graphs name is counted in the first one loaded here (sim, then audio, UI, fighter view, animation, planet, pane, split, vfx, boot, main).
- **Engine init is the second item** (21% at x4), and I have not split it further (no engine symbols in the release template).
- `_ready` itself is small (0.3 s at x1, 0.85 s at x4).

## The full boot, seconds from page start

| | x1 | x4 |
|---|---|---|
| Ready end / first frame | 4.4 to 4.5 | 15.5 to 15.6 |
| Match and panes built in steps (step_load to step_boot) | 2.4 | 7.1 |
| Shader compile in steps (step_boot to boot_done) | 16.0 | 18.0 |
| **Playable (boot done, match running behind the card)** | **22.6 to 23.5** | **40.7 to 41.1** |
| Longest block | 4.4 (the start) | 15.5 (the start) |
| Longest frames after the first one | 3.7, 2.9, 1.9, 1.0 s (the last four programs, terrain, water, building, cover) | 3.9, 3.0, 2.1, 1.05 s |
| Frames over 250 ms in the run | 17 | 26 |
| Audio warm-up end | 24.8 (1.3 s after boot done) | 116.4 (75 s after boot done) |
| Cues skipped | 0 | 1 (flash.hurt.circles) |

- **The last four compile frames do not scale with the CPU** (3.7 s at x1, 3.9 s at x4): the graphics driver compiles them. On a phone's driver they will differ; not measured.
- The quiet budget does reach the audio warm-up in the boot (x1: done 1.3 s after boot done; x4 warm-up is still 75 s long after the first-run card is dismissed 2 s after boot done in the probe; a player who reads the card for 10 s shortens it). Skips: 0 at x1 and 1 at x4 (was 9 to 11 at x4 with warm-async 2).
- Before the pieces, the same page was one 26 s block at x1 and 48.5 s at x4 (no park); now the longest block is 4.4 s and 15.5 s and the page draws a line and a bar from the first frame to playable.

## The breadcrumbs report with the switch on (cr3 export, build unknown: no build_info in a scratch export)

Stages read, x1 / x4: `page_loaded` (the start block; its stall 4.7 s / 15.2 s is named right) -> `card` at 4.7 s / 15.2 s -> `running` at 23.2 s / 40.0 s (= boot done). Correct, with one gap: **`card` is held through the whole staged boot** (`_crumb()` returns early while the match loads or the boot compiles, and the first-run card is up), so the 3.8 s, 3.0 s, 1.6 s freezes of the compile are labelled `card` in the report, and the page's static line ("the first start can take a minute...") is hidden from the first frame. A phone's report would say "stall 7 s in the card". Fix (Rendering, `main.gd` `_crumb()`): say `loading` while `host.loading()` or the build queue runs and `compiling` while `boot` runs, ahead of the card test; the crumbs script takes any stage name and prints it (no word change needed).

## What would shorten the start block (not measured)

A bootstrap main scene: draws the line at once, then loads the script graphs one per frame (`load()` of the sim graph, the UI, the render graphs) so the page draws between them. The block becomes the biggest single load: SimHost's 6.4 s at x4 (from 15.5), 1.2 s at x1; splitting the sim graph into two or three entry loads cuts it further. The total time is unchanged. Owners: Rendering (main, boot) with Simulation (the sim graph's entry points). Lazy loading of what the first match does not need (the later fighters' kits, tools-only classes) would cut the total, and is Simulation's call.

## Not covered

A real phone; x6; the download on a slow network; the engine-init split; the driver's compile on a phone's GPU; three or more runs per cell.

## Files

`scratch-hooks/hook-bootprof3.mjs`, `make-audit-sites.mjs` variants `bp3` and `cr3`, `freeze-probe.mjs` (page-side wasm marks, `resources`). Raw runs in my scratch folder (`w/farun6/`, `farun7/`, `farun8/`).

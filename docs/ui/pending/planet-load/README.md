# Park: the planet loading screen, the early start and Back (re-cut to GD's ruling, 2026-10-26)

UI, on the EP's brief and Game Design's ruling (rulings 10-26 item 27): the load begins as soon as the planet's seed is known, while the player is choosing, and starts over if the choice changes; whatever wait is left keeps a Back to the menu with nothing kept, answering from the first frame. Based on HEAD 0c62c856 (Simulation's planet-load is on main; the three Rendering and UI files the patches touch are byte-identical to it). Account: `docs/ui/planet-load.md` (inside the UI patch).

## What it is

- **The screen:** one line of words and a thin bar on the start menu's dark ground, and under them a Back to the menu button. No number, tip, fade, wipe or blur, nothing moves but the bar's end (ADR 0010, taste.md). The bar redraws once a whole percent. Five lines, one per `job.phase`, in `ui/data/terms.json` (`prompt.load_*`), and `prompt.load_back`. Nothing about people (Legal c08).
- **Early start:** `SimHost.prefetch(setup)` is told the planet part of the menu's choices whenever they change (new HUD signal `menu_changed(config)`; main's `planet_part(cfg)` reads `planet`, `planetGen`, `touch`, `arena`) and makes it a slice a frame (`prefetch_step`, called from `frame()`). Same choice: the work stays. Another planet, generation, arena or touch-down: it starts over. No planet, gen 1, already made, or a tool (strict off): nothing. Start then takes up what is left of that very job (`new_match` adopts it), so the screen starts part-way filled or never shows.
- **Back:** Esc, a pad's B, or a click or tap on the button (`loading_back_requested`). Main calls `host.cancel_load()` (drops the load, the call it waited for and the planet made ahead; what World has already memoised stays), hides the screen and opens the start menu again. The menu is rebuilt from the saved choices, which carry no planet pick, so nothing restarts the load by itself. Every other press does nothing while the screen is up (a pad's A, Enter, P, a click off the button).
- Gen 1 matches, setups with no planet and planets already made never wait. Today the menu has no planet row, so `planet_part` returns {} and nothing is made ahead and no screen shows; it all starts when a menu row, the campaign or the planet picker puts `planet` in the choices (that is the one place to wire).

Stills (the real build, a web export, headless Chrome through the launcher, session tag `ui-ux`): `mid-load-1280x720.png`, `mid-load-390x844.png` (the button at the menu's touch size on a phone), `after-back-1280x720.png` (Esc or a click on the button, a few seconds into the load: the start menu is back). The menu's look is unchanged, so no side-by-side.

## Two patches, in this order from the repo root

```
patch -p1 < docs/ui/pending/planet-load/planet-load-ui.patch      # UI's own files (ui/, docs/ui/planet-load.md)
patch -p1 < docs/ui/pending/planet-load/planet-load-grant.patch   # Rendering's two files: needs the EP's grant
```

sha1: planet-load-ui.patch 60eea2e9e9be5cf5736ee715e40295ea0ea605d0; planet-load-grant.patch 481f5b06cdfb692e55888797f3b73f0addc47cc6.

`planet-load-ui.patch` is safe alone (nothing calls the screen until the second lands): `ui/widgets/ui_loading.gd` (+ .uid), `ui/hud/ui_hud.gd` (the layer under the notice, `show_loading`, `hide_loading`, `is_loading`, Back input, signals `loading_back_requested` and `menu_changed`), `ui/data/terms.json`, `ui/tools/hud_check.gd` (`_loading_rules`), `ui/tools/load_check.gd` (+ .uid), `docs/ui/planet-load.md`.

## NEEDS FROM EP: the grant (Rendering's files), in `planet-load-grant.patch`

- `render/core/sim_host.gd`: `load_job`, `_load_call`, `pre_job`, `_pre_key`; `planet_key(setup)`; `prefetch`, `prefetch_step`, `cancel_load`; `new_match` returns early with the sim untouched when strict and `not SimPlanetLoad.mayStart(su)` (adopting the prefetched job when its key matches); `loading()`, `load_phase()`, `load_progress()`, `load_step()` (runs the kept call with strict off for that call only, so a planet that still read as cold is made there, never looped on).
- `render/core/main.gd`: `SimPlanetLoad.strict = true` in `_ready` when `not manual`; `start_match` shows the screen and returns when `host.loading()` (the rest is `_match_built()`); `frame()` starts with the load step and then `host.prefetch_step()`; `_input` (after the touch-mode update) and `_unhandled_input` return while loading; `planet_part`, `_on_menu_changed`, `_on_loading_back`, `_planet_next` (merged into the match's own setup by `_match_setup`, and passed with `--intros` off), `_match_ever` (a Back before any match was built starts a plain one under the menu, as at boot). `_on_menu_started` sets and clears `_planet_next` around `start_match`.

## Gates (a scratch tree of HEAD + both patches, below-normal priority, one Godot at a time)

- UI recipe: hud_check 5816 checks, 0 failed (with `_loading_rules`: Back by Esc, a pad's B and a click on the button; P, Enter, a held Esc, a pad's A and off-button clicks do not; the button at the menu's touch size at ten sizes; `menu_changed`); determinism plain and `--intro --seeds=2 --ticks=900` passed; hud_words passed; pane_check passed.
- `ui/tools/load_check.gd`: 28 checks, 0 failed (the earlier 14 for the host's load, plus prefetch: same choice keeps the work, another planet starts over, Start takes up that very job and its progress, a planet made ahead means no screen, no planet or gen 1 or a tool never prefetches; `cancel_load` leaves nothing and the same choice then starts afresh).
- Render gates, gen 2 off: after, cue (`--profile=spaced`), depth, flash, flash_reg, flight, ground, lane, open, patch, shape, sky, stage, city, seam_sweep (1280x720) all exit 0 with their pass line; sim parity golden check passed.
- The web export was driven end to end: the screen shows from the first frame of a gen 2 load with Back on it; Esc and a click on the button each put the start menu back; a load that finishes starts the match (first-run card over it). A web run on this busy machine is a lead only, not a measurement.
- No flash run: steady shapes and a bar that redraws at most a hundred times in a load; nothing is drawn over a fighter.

## Redoing the stills (scratch only, not in the patch)

Three edits to `render/core/main.gd` in a scratch export, so no public build can ask for a gen 2 planet: add `"gen2"` and `"slowload"` to `URL_ARGS`; in `_match_setup`, once per session (an `Engine` meta flag, not `_match_ever`: Back's plain match must not ask again), add `planet` (the seed), `planetGen` 2, `arena {"cols": 2400}` when `args.has("gen2")`; in `_ready` before the strict line, `SimRun.planetUnitsPerRead = maxi(1, int(args["slowload"]))` when `args.has("slowload")`. Then `/play/?nonotice&gen2&slowload=2` (a stock load is over in a second or two). The page takes 10 to 30 s to boot on this machine, so a key or click sent at a fixed time can land before the screen is up: wait long enough with a slow load.

## Traps

- The first stills of Back showed no response because my scratch hook added a gen 2 planet to every match the game started, including Back's plain one, so the load began again. Not the patch's behaviour (the one-shot flag fixed it).
- A cold load on an old laptop or phone is long: the screen is the first thing drawn, because `start_match` shows it before `frame()` runs the first slice, and Back is live from then.
- `_on_menu_started` claims devices right after `start_match`; with a load the kept `new_match` call recomputes `hub.setup()` later. Claims do not change what it returns today.
- A prefetch slice (about 5 ms a frame) runs while the menu is up, under the gate; on a phone that may cost the menu a few frames. Performance to bench it when the menu has a planet row.
- World's memo keeps a finished planet: Back drops the work, not a planet that was already made.

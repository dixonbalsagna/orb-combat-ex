# The planet loading screen

UI's screen for the wait while a gen 2 planet is made (Simulation's `SimPlanetLoad`, docs/architecture/planet-load.md), and the host's hookup that shows it. Written 2026-10-26; re-cut the same day to Game Design's ruling (rulings 10-26 item 27): the load starts early, and the screen has a Back.

## What the player sees

A calm dark ground (the start menu's), one short line in the dim ink saying what is being made, and a thin bar under it that fills as the planet is made. Nothing else: no title, no number, no tip, no spinner, nothing over, between or beside anything. It does not fade in, wipe or blur (ADR 0010, docs/ep/taste.md), and nothing moves but the bar's end. It is there while the planet loads and gone when the match is built.

The bar redraws once a whole percent (a hundred times in a load at most, and not at all on a frame where nothing changed). Nothing flickers, so nothing needs a Reduce flashing version.

| phase (`job.phase`) | the line (`prompt.load_*` in ui/data/terms.json) |
| --- | --- |
| plates | Raising the continents |
| climate | Setting the winds and weather |
| rivers | Cutting the rivers |
| places | Founding the towns |
| ring | Laying out the ground |

A phase this build does not know says the first line's words, never a path. The lines say what the planet is made of and nothing about people (Legal c08: no count, no toll; this is a place being made).

## Two rules from Game Design (item 27)

**The load begins as soon as the planet's seed is known**, while the player is still choosing, and starts over if the choice changes (generation is pure from the seed). The host does it: `SimHost.prefetch(setup)` is told the planet part of the menu's choices every time they change (the HUD's `menu_changed` signal, and once when the menu opens; main's `planet_part(cfg)` reads `planet`, `planetGen`, `touch` and `arena` from them) and makes the planet a slice a frame (`prefetch_step`, called from `frame()` while no load screen is up). The same choice leaves the work alone, another planet, generation, arena or touch-down starts over, and no planet, a gen 1 one or one already made drops it. When Start comes, `new_match` takes up what is left of that very job (so the screen starts part-way filled, or does not show at all if the work is done) rather than starting a second load. Only in the game (strict); a tool never prefetches. The menu has no planet choice yet (`planet_part` returns {} until a menu row, the campaign or the planet picker puts `planet` in the choices), so today nothing is made ahead.

**The wait that is left has a Back.** A button under the bar, Back to the menu, from the first frame (it is drawn by the same call that starts the screen, and the HUD answers input while the screen is up): Esc, a pad's B, or a click or tap on it. The HUD emits `loading_back_requested`; main drops everything (`host.cancel_load()`: the load, the call it waited for and the planet made ahead; what World already memoised stays, it is the planet's), hides the screen and opens the start menu. Nothing is kept: the menu is built from the saved choices, which carry no planet pick, so nothing starts the load again by itself. If the load was the session's first match (only possible from a planet-named boot), a plain match is started under the menu first, as at boot. Every other key, a pad's A or Start and a click off the button do nothing meanwhile (no press reaches a match that does not exist), and P does not open the pause menu.

## How it is built

- `ui/widgets/ui_loading.gd` (`UiLoading`): pure `plan`, `sig` and `draw`, like the other widgets. `plan` centres the line over the bar in the safe area; `fits` is true when both are inside it. Progress is floored to a whole percent, so the picture is the same between percents.
- `ui/hud/ui_hud.gd`: a layer of its own (`_l_loading`) over every menu and the match and under the notice (a photosensitivity gate that is still up shows first). `show_loading(phase, progress)` is called a frame by the host and works before any match is built (the HUD has no fighters at the start of a load); `hide_loading()`; `is_loading()`. While it is up the HUD reads only Back (`_loading_input`) and ignores the rest. Signals: `loading_back_requested`, `menu_changed(config)`.
- Nothing here reads or writes the sim. The HUD is only handed the two values.

## The host hookup (Rendering's files, a patch under the EP's grant)

- `render/core/main.gd`: `SimPlanetLoad.strict = true` at the top of `_ready`, only when `not manual` (the game's own main; a tool's main leaves it off, so the tools make their planets as before). `planet_part(cfg)`, `_on_menu_changed` (calls `host.prefetch`), `_on_loading_back`, `_planet_next` (the planet part Start merges into the match's setup, in `_match_setup`), `_match_ever`; `frame()` calls `host.prefetch_step()`.
- `render/core/sim_host.gd`: `new_match` computes the setup as before; when strict is on and `SimPlanetLoad.mayStart(su)` is false (a gen 2 planet not made), it starts a `SimPlanetLoad.beginFor(su)` job, keeps the call and returns without touching the sim. `loading()`, `load_phase()` and `load_progress()` read the job; `load_step()` spends `SimRun.planetUnitsPerRead` units and, when the planet is made, runs the kept call (with strict off for that one call, so a planet that somehow still reads as cold is made there and never looped on).
- `render/core/main.gd`: `start_match` shows the screen when the host is loading and returns; the rest of its old body is `_match_built()`. `frame()` starts with `if host.loading(): _step_load(); return` (a slice of the load, then the screen reads phase and progress; the frame the planet is made it hides the screen and calls `_match_built()`). The sim, the panes and the HUD's `advance` do not run during a load. `_input` and `_unhandled_input` ignore the match's input meanwhile.
- A gen 1 match, a setup with no planet and a planet already made never see the screen: `mayStart` is true and `new_match` runs as it always did.

No path in the game builds a gen 2 planet setup yet (`_match_setup` adds only the intro), so today the screen is never shown. It appears when a menu, the campaign or the data asks for a `planet` with `planetGen` 2.

## Checks

- `ui/tools/hud_check.gd` `_loading_rules`: every phase has its own short line; at ten sizes the line, the bar and the Back button fit the safe area (the button at the menu's touch size, under the bar), over the text floor; the bar only grows and is held to 0 to 1; the picture changes by whole percents; on a real HUD with no match built, up, redrawn at most 101 times over a thousand steps, gone on hide; Back: Esc, a pad's B and a click on the button each ask once, and P, Enter, a held Esc, a pad's A and clicks off the button do not; the menu says when its choices change.
- `ui/tools/load_check.gd`: the host with strict on. A match with no planet or a gen 1 planet starts at once; a cold gen 2 planet waits without touching the sim, the phases come in order, progress never goes back, the match then starts and is the same match (gameplay hash at tick 0 and after 120 ticks) as one started with strict off; a planet already made does not wait; prefetch (the same choice leaves the work, another starts over, Start takes up that very job and its progress, a planet made ahead means no screen, no planet or a gen 1 one or a tool drops or never starts it); cancel_load leaves nothing (no load, no work ahead) and the same choice then starts afresh.
- Still: the screen mid-load on a gen 2 setup, from a web build with a scratch-only `?gen2` hook (see the park's README).

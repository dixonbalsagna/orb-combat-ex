# A5: Rendering & Technical Art

Leads: A-RENDER-05, A-RENDER-06, A-WORLD-05
Supports: none

Goal: A player sees craters and trenches exactly where their fighter stands with nothing popping into view, and a tester on a Steam Deck gets a picture-quality setting that visibly does something, starts at a level the Deck can hold, and is still set after a restart.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5; the A-RENDER-06 line of "Rows proposed smaller for Alpha"; decision 3 and decision 19); `docs/decisions/0012-turntable-and-quality-range.md`; `docs/perf/quality-range.md`; `docs/ep/proposals/terrain-globe-plan.md` (section item 9 at lines 56 to 59, the caveat at line 149, and step 4 of the step table); `docs/rendering/pending/2026-11-01h-store-bowls/README.md`; `render/core/main.gd` lines 165 to 226; `render/core/look.gd` lines 592 to 598; `render/core/ground_field.gd`; `render/shaders/tile_vertex.gdshaderinc`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`; the Deck readings from A2 to A4, which the EP will send.
- A-RENDER-05: Settings offers "Effects quality" (auto, high, medium, low) but no game code reads the choice. Evidence: `ui/data/options.json:52` (the option `vfx_quality`); `ui/hud/ui_hud.gd:85`; `render/core/main.gd:168-172` (only the launch word `vfx-quality` sets the level).
- A-RENDER-06: the quality range is a paper ladder; the game has no working level picker, no Deck default, and an automatic step that pins a 30 frames-a-second machine at low. Evidence: `docs/decisions/0012-turntable-and-quality-range.md:9`; `docs/perf/quality-range.md:7` and `:30`; `render/vfx/vfx_hub.gd:156-158` (the automatic step goes down at 42 frames a second).
- A-WORLD-05: the ground drawn is not the ground stood on. Evidence: `render/core/look.gd:596` (only the 16 nearest crater bowls are drawn); `docs/ep/proposals/terrain-globe-plan.md:54-58` (planet trenches and beam scars are not drawn, but feet and props stand on them); `docs/ep/vision.md:1690` and `:1695` (Orb's reports).

You own: `render/core/`, `render/shaders/`, `docs/rendering/`.
- The level each effect draws at is VFX's code (`render/vfx/`), the Settings row is UI's (`ui/data/options.json`), feet are Animation's, and the trench and scar records are World's (`sim/world/`). The EP briefs each; ask for what you need under NEEDS FROM EP and do not message them.
- ask under NEEDS FROM EP for a grant: `data/vfx/perf.json` (no owner), if a level's caps live there.
- ask under NEEDS FROM EP for a grant: `render/main.tscn` or `project.godot`, only if a level needs a scene or project setting; name the line.

Acceptance criteria:
1. (A-RENDER-05) Choosing low, medium, high or auto in Settings changes what is drawn in the running match, and the choice is read back at start-up. Checked by: a test that sets each choice and reads the live level from the game (the effect, not only the saved value), saved under `docs/rendering/runs/<sha>/`; UI's settings round-trip test (A-UI-10) covers the restart on Windows and Linux (X-20).
2. (A-RENDER-06, the smaller version proposed for Alpha) Three working levels sit behind the existing "Effects quality" row: low, the Deck's default, and the PC's default. Each level states in `docs/rendering/` which dials it moves (picture size, ground detail, crowd, effects, animation) and each differs measurably from its neighbour. Checked by: a frame record per level on Orb's PC and a tester's bench file per level from a Deck, saved under `docs/rendering/runs/<sha>/`. Full version if Orb declines the proposal: the whole ladder from performance up to the PC's default, each step measured (L; the steps above that stay after Alpha as A-RENDER-10).
3. (A-RENDER-06) A Steam Deck starts at its own default level without the player choosing, and that level is the one the Deck's real readings from A2 to A4 support; the automatic step no longer pins a machine holding 30 frames a second at low. Checked by: a bench file from a real Deck at the default level, read against the Deck figure Orb confirmed (decision 19). This is the level X-24 is measured at in A6.
4. (A-RENDER-05, A-RENDER-06) A setting changes what is drawn and never what the sim computes (ADR 0012 item 3). Checked by: the same seeded match gives the same state fingerprint at every level; result saved.
5. (A-WORLD-05) Planet trenches and beam scars are drawn, craters are built into the ground tiles once, and no crater pops in or out in view. Checked by: your drawn-versus-stood-on probe (terrain-globe-plan step 0 names it; build it if it does not exist) reading within 8 units under each fighter's feet over 10 seeds, and zero pops in view; QA runs the ten seeds and saves the reading.
6. (A-WORLD-05) The cost of rebuilding tiles is measured, on the reduced record store as the plan asks, and the worst frame it causes is inside X-23's 50 ms on Orb's PC. Checked by: Performance's frame record, saved; a miss goes to the EP before the change lands.
7. (all three) Look gate (ADR 0010): each change that alters the picture ships with a side-by-side against the reference build named in `docs/ep/taste.md` on the day (`node tools/flash/side-by-side.mjs`, same scene, same ticks), looked at by the EP before it is committed; for the levels, one set per level. No level may use a dissolve, a fade, full-screen blur or haze to save time, and "low" keeps every warning and every edge-of-screen readout. Both modes of the flash check are run on the changed picture before the look report.
8. (all three) Gate results are saved as small text under `docs/rendering/runs/<sha>/` (CD-22), including your own render checks on the configuration Orb plays.

Constraints:
- Tokens: about 8.25M at the register's classes (two L, one S); about 5.45M if Orb accepts the three-level proposal. Estimates.
- State hash: none of the three rows may change the sim's state fingerprint. If drawing trenches needs a change under `sim/world/`, stop and tell the EP: it would have to wait for a golden window, and A5's only window takes numbers, not rules.
- Machine: headless Godot only (pictures come from the web build through Tools' launcher, `tools/machine/capture.mjs`, one capture at a time, never your own browser script); at most 3 Godot processes for a short gate; benches and long sweeps at below-normal priority; a frame reading taken while the machine was saturated is void.
- Determinism: rendering reads sim state and never writes it; level numbers live in data, and a change to a data file's shape updates its schema in `tools/schemas/` in the same commit.
- Originality: every shader and look is our own.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves or fades; no presentation effect that drops the frame rate; an old machine's level never sets the look for anyone else (ADR 0012 item 2); plain words in the level names and help text, which Orb sees before use.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A-WORLD-05 starts only after A-WORLD-03 (terrain step 2, in A3) is on main, and after the globe ground and crater look became defaults in A1 (A-RENDER-01, A-RENDER-04). The levels start once the Deck's readings from A2 to A4 are in and Orb has confirmed the Deck figure. With 8.2M of lead work this is the heaviest queue in A5: the EP may start A-WORLD-05 during A4 behind a switch. UI's quality row, the X-20 round trip, QA's ten-seed reading and A6's X-23 and X-24 readings wait on this brief.

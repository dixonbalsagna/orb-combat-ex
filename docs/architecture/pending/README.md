# Pending core slices

Owner: Simulation and Engine. Nothing in this folder is run by CI, the validator, the sim or Godot (`docs/` is hidden from Godot). It holds slices that are built and proven in a scratch copy and wait for the sim slot.

**A parked build:** `hitstop2/`: hit-stop by weight re-cut to Game Design's 5b (the table 2, 3, 5, 8, 12, 14, 20, 24; over an 18% budget of a rolling 10 s, every stop under a decisive blow ×0.75), and a stop of n ticks freezing n (the count-down's float residue gave n + 1), behind the hit-stop switch; with Tools' schema lines (`grant_tools.py`). No golden moves. Its page is `../feel-core.md` section 7.

**A parked build:** `ricochet/`: the ricochet's glance, re-cut to Game Design's 4, behind `data/fight/ricochet.json` (off): at 1,500 u/s of his whole speed, a contact under 40° with a building's face or ground sloped 30° or more glances on at 0.7, at most two in a row; flatter ground keeps its skid, bounce, tumble and slam; the `ricochet` event; `SimRicochet.predict` for the choreographer. With World's lines (`grant_world.py`) and Tools' schema (`grant_tools.py`), same commit. No golden moves. Its page is `../ricochet-core.md`.

**A paper, not a build:** `arena-conditions.md`: my conditions on World's shifting arena (windows 0 and 1), with the exact lines: the `arena.cols` guard, and one sim's world statics bound again at every step.

**A parked build:** `boons/`: the run's three rare boons (Born ready, Second skin, the borrowed form), run-only: a setup names them, and versus never does. No golden moves. Its page is `../boons-core.md`.

**Tools' schema for `data/fight/boons.json`** is `grant_tools_fight.py` (it also held catastrophe, flight and hitstop, applied with c09c3bef): run it after `boons/`; it writes only what is missing.

Each applies alone on main (c847bf8f or later); `hitstop2/` and `ricochet/` are proved together.

The air brake's second window (`brake2/`: air sense 10%, the window from the launcher's power, a flight's end clears it, Controls' `brake_ready`) was applied in 982b7b65 with World's, Encounter's and Audio's grants, and the script is deleted. Encounter's three asks (`shared/`: the curve's shared functions, `SimBrake.controlBack`, the camera feed out of the light digest) were applied in c6980e25 with World's arena windows 0 and 1 (`arena-conditions.md` is the review, kept as the record), and the script is deleted. The launch's curve and hit-stop by weight (`feel/`), the forms' working rule (`forms3/`) and the blast cloud's cue and ash (`cata/`) were applied in c09c3bef (2026-10-20) with Tools' schemas, and their scripts are deleted. The pages are `../feel-core.md`, `../forms-core.md` section 8 and `../run-core.md` section 6.

The forms (`forms/`) were applied in 8f157894 (2026-10-17) with Encounter's four lines, their branches (`forms-branches/`) in 421134e0, and the air brake (`brake/`) in 167a10a2 (2026-10-18) with World's `brakeEnd`; their scripts are deleted. The pages are `../forms-core.md` and `../brake-core.md`.

Animation's view fields (`anim-events/`: a launch's tier; a hit's hit-stop ticks and the hitter's tier, outside the hash) were applied in 97a7cf73 (2026-10-17), and the scripts are deleted; the fields are in `../fx-events.md`.

Windows 2 and 3 of `../fighters-as-data.md` (the reference fighter on a bench, the selection guards) were applied on f5c001e6 (2026-10-13) and their scripts are deleted.

Stage 1 of one versus many and the training dummy in the roster (`n-bodies/`) were applied in 06b0200e (2026-10-16); the page is `../one-v-many-core.md` and the scripts are deleted.

The weight on the damage event (`weight_event.py`) was applied with Encounter's chain (3198301f), and its script is deleted.

A fighter's depth outside a flight (`depth-a/`) was applied in 46734840 (2026-10-17), switched off, with Encounter's D1a; the page is `../depth-core.md` and the scripts are deleted.

The tier cap (`tier_cap.py`) was applied on 8106e07a (2026-10-12) and its script is deleted.

Shots, the second round, was applied on cf0466f with both of its switches off (`docs/architecture/shots.md` sections 13 to 18), and `shots2.py` and `shots2_schema.cjs` are deleted.

**What is left of it is two data flips,** each a behaviour change with one golden regeneration, in `data/fight/shots.json`:

| Flip | When | Proven in scratch on 2c91129 |
| :--- | :--- | :--- |
| `"structures": false` to `true` (done in World's window, bc0adfe) | In World's window, with World's `WorldBlast.shotBuilding` as the body of `SimShots.hitStructure` (one line in `sim/core/shots.gd`, by grant) | 4 of 9 golden matches move; parity and determinism pass |
| `"scatter": false` (under `deflect`) to `true` | With Encounter's lines for agency-pass 15.2 (the free approach, the context deflect, the feed text), after QA's measuring | 7 of 9 golden matches move; parity, determinism and the loader check pass |

The 100-match figures for each are in `shots.md` section 18.

Game Design's section 17 code items (the fuse by cause, `chainR` at every tier, the wild flight's speed and its arc by band) were applied on a56187a (2026-10-03). Tools' schema for the renamed keys is Tools' own parked script, `docs/tools/pending/apply-shots.cjs`.

**A written plan, not a build:** `shots-events-and-kinds.md`: VFX's four event asks on `shot_end` and `mine_trip`, and the kinds rain, split and curve for the launch pair (ricochet later). For my next window in the sim tree.

Dynamic intros, the first cut, was applied on 648c637 (2026-10-06); the plan is now `docs/architecture/dynamic-intros.md`, as built, and its parked build is deleted.

**Notes, not a build:** `zip-and-brawl-core-notes.md`: short answers for Encounter's zip slice (the point rush, shots on the way out, the tackle's `held` state, exhaustion) and for brawl B1 (`DirS.brawlI`, and what can move or free a locked fighter).

**Done, kept as a record:** `fighter-split.md`: the rename of the roster ids to `PROTAGONIST` and `RIVAL` (committed as bf71a834, 2026-10-06).

What is asked of the core and not yet built is listed in `core-backlog.md`.

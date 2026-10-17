# Pending core slices

Owner: Simulation and Engine. Nothing in this folder is run by CI, the validator, the sim or Godot (`docs/` is hidden from Godot). It holds slices that are built and proven in a scratch copy and wait for the sim slot.

**A parked build:** `forms-branches/`: the forms' second window, Witness and Trial (Game Design's `hero-forms.md` section 3 and the pick), behind the forms switch; with World's two lines (`grant_world.py`) and Tools' schema lines (`grant_tools.py`, same commit). No golden moves. Its page is `../forms-core.md` section 7.

**A parked build:** `brake/`: the air brake (Game Design's `buildings.md` section 7.2) and Animation's `air_brake` event, behind `data/fight/brake.json` (off); with World's one function as `grant_world.py`. No golden moves. Its page is `../brake-core.md`.

**A parked build:** `forms/`: the Protagonist's five steps and the slingshot (Game Design's `hero-forms.md` sections 4 and 4b), with the hold and release signals for the waiting game, behind `data/fight/forms.json` (off); with Encounter's four director lines as `grant_encounter.py`. No golden moves. Its page is `../forms-core.md`.

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

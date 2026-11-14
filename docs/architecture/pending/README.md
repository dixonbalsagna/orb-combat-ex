# Pending core slices

Owner: Simulation and Engine. Nothing in this folder is run by CI, the validator, the sim or Godot (`docs/` is hidden from Godot). It holds slices that are built and proven in a scratch copy and wait for the sim slot.

**Landed in the Sunday batch (4890bdd9), their folders deleted:** `power-travel/` (a setup's `"travel"`, with Netcode's and Tools' grants and the stance-freeze doc lines) and `power-page/` (Tools' page lines: the model on for the page, and the travel slider).

**Parked, sprint A1:** `meters-zero/` (A-ENERGY-05, Orb's decision 6): the old meters change nothing, the comeback is a rule for both fighters (Narrative's grant for the data). Changes the hash: GW1b.

**Parked, sprint A1:** `replay-sizes/` (support for World's five planet sizes): a replay's header is made at the size its setup names, so a sized planet's replay plays in a host bound to another size; applies after World's three parks. No change for medium.

**Parked, sprint A1:** `energy-on/` (A-ENERGY-04): the one energy model and the dash on in main's data (a grant), with the rows written for them off pinned; it replaces `power-flip/`, deleted. Changes the hash: GW1a.

**Parked, sprint A1:** `a1-owed/`: hit-stop by weight's never-cut list (heavy, launch, launch_full: Game Design) and power_check's close times to striking distance with the arrival off and on (needed before GW1a lands the arrival in main's data); the docs' underTicks 12 is edited in place. No state change.

**Parked, sprint A1:** `replay-build/` (A-NET-05): a replay names the build that made it (Tools' stamp, `build_info.json`), and another build's replay is refused before its first tick with a reason and both ids; the sentence is UI's. No state change. Lands before golden window GW1.

**Landed in 6a30b4c9 (Orb's 16:30 build), their folders deleted:** `dash-slip/` (a dash let go before tick 12 eases to the slip's 1,125 a second over 4 ticks, with Encounter's slip-arrive and its undertick grant) and `hitstop-any/` (the freeze budget on any table at Game Design's 12% and ×0.7, heavies never cut, the hp clause gone, weights named with the budget on). The run records are in `docs/sim/runs/592a807b/dash-slip/` and `docs/sim/runs/578e819e/hitstop-any/`.

**Landed in 6eec6a75, their folders deleted:** `power-dash/` (LT held at the level's flat out at any range, behind its switch, with Encounter's arrive) and `cd05-witness/` (CD-05: the menace hold at the cap gone, Witness from the city wrecked).

**Parked, the one energy model's second half:**
- `power-flip/`: replaced by `energy-on/` (A1), and deleted.

**Landed, its folder deleted:** `parity-wired-sources/` (parity's wired rows after World's no-casualty-feed; a row whose path is gone fails by name).

**Landed in 1931a0f8, its folder deleted:** `anchor-midpoint/`. The line re-anchors at rest by its midpoint, not fighter a; memo wipes in 40,000 ticks are down from between 166 and 374 to between 6 and 15.

`clock-by-body/` is a prototype, not for landing; its README has the proof.

Landed in the morning batch (a8bc66e2), their folders deleted, for co-op 2v2: `outside-key/` (A1, a setup's `"outside"`), `stage-cap/` (A6, 2v2's time cap on one stage clock), `event-lists/` (the picture's lists on NetLan's fight-1 PC), `outside-shots/` (a shot from outside meets a building or the ground as its shooter's), with Encounter's and World's grants; and `brake-parity/` (parity's air brake rows with the switch either way). The page is `../cross-fights.md`.

Landed in d5582dbd, their folders deleted: `loop-path/`, `ceil-reach/`, `power-core/` (page `../power-core.md`, not yet committed).

Landed in the overnight batch (3c9005ac), their folders deleted: `field-place/`, `field-static/`, `ceil-table/`, `places-records/`, `cross-fights/` (page `../cross-fights.md`), `cross-end/` (page `../cross-end.md`), `fights-check-turn/`, `swing-check-page/`.

Landed, their folders deleted: `kick-keep-top/`, `refactor-1-point-at/`, `refactor-3-clock/`, `refactor-6-view-clock/`, `refactor-2-pair/`, `ring-warm/`, `hash-beat-lists/`, `ending-forward/`, `fight-swap/` (page `../fight-swap.md`), `places-check-front/`.

A plan's coarser reads, the match key's fresh sample (`field-frame-2/`) and a building's base at its own point, a standing fighter keeping the floor, `groundCeilAt`, the narrower pose pass and the marks laid at rest (`field-pads/`) were applied in 0af72600; their folders are deleted.

A field world's line and the turntable (`field-frame/`) was applied in 59e671ed; its folder is deleted.

The intent's second word in the hash and the replay and the struggle flag (`right-word/`) was applied in 58a49f5c; its folder is deleted.

Spawn-floor (a fighter starts on the floor of a lake or the sea, with Game Design's row 13 on entrance craters) was applied in aff21131; its folder is deleted.

The computer's level in the replay header from the match's setup (`ai-level-hash/`, UI's patch with one line of mine in `sim.gd`) was applied in 0ba71199 with Encounter's review, the cross-process replay check (`replay-xproc/`, `../determinism.md` section 10) in bed20962 with Tools' CI steps, Netcode's two lines for a past snapshot's hash (`simhash-past-roots/`) in 8591e30a, a planet's data in the header (`density-hash/`) in 6a993bd8, and the rest of it (`planet-header/`: `lakes.json` and `ground.json` for gen 2, `rings.json`'s `turn` while the turn is on) in 43c4d272 with World's lake-floor, and parity's fixtures in a folder of the run's (`parity-fixtures/`) in 39cf9233; their folders are deleted.

Packed structures (the buildings and trees as packed arrays, the desync digest's fix and `two_states_check.gd`, page `../packed-structures.md`) was applied in 5a2c58c2 and World's turn fix in e14757c5; their folder is deleted. The director's named forwards for World's calls and the data warm-up as a match-start piece (pages `../load-split.md` and `../match-start.md`) were applied in 39f6bc3f with Tools' CI step for load_split's negative control, and the calm turn in `two_states_check`'s default setups in 112b0e6c.

The planet's pacing in the run's data (`units-to-data/`: `ground.planetUnitsPerRead`) and the campaign's first slice (`docs/sim/pending/campaign-slice1/`) were applied in 622a0465 with Tools' grants, and slice 1b (`campaign-slice1b/`, on World's real calls) in 223ffdcc with Tools' and World's. Also applied: slice 1c (`campaign-slice1c/`, the cross-back) in c9bd20d1; the planet's load step (`planet-load/`) in 0c62c856 with World's lines; the campaign's load of its arc's planet (`campaign-load/`) in b2793a1e; a match's start in pieces (`match-start/`, page `../match-start.md`) in d9d4fb2d with World's and Rendering's lines; and the calm turn's read at a total K of 12 a tick on a gen 2 planet (`calm-k/`, page `../calm-turn-read.md` §6) in d7647634 with World's, Encounter's and Tools' lines; the sim's load split (`load-split/`: `SimDir`, page `../load-split.md`) in 8ce4be37 with World's lines; and web parity's engine label (`web-parity-label/`, page `../web-parity.md`) in bb988c0e with Tools' CI step. Their scripts are deleted.

**A paper, not a build:** `arena-conditions.md`: my conditions on World's shifting arena (windows 0 and 1), with the exact lines: the `arena.cols` guard, and one sim's world statics bound again at every step.

The run state and its carry (`run-state/`) were applied in 502e67e7 with Tools' grant. The web-parity check (`web-parity/`) was applied in 3b65e513, and Tools wired it into CI (d435ca1d). The first stage on World's stepped `beginFirstRing` (`first-ring-host/`) was applied with World's first-ring, and its script is deleted. The run's stage ground (`run-ground/`: `SimRun` and each stage's ring, re-cut for the used rings and the boss's waiver) was applied in 07876704 with World's used rings and Tools' grant, and its scripts are deleted. The mash flow and the budget's deep step (`mash-flow/`, Game Design's 6 and 7d) were applied in e90590b8 with Encounter's naming and Tools' grant, and the sim's own pi and tau (`simmathx-pi/`) in 74ee6b04; their scripts are deleted. The ricochet's glance (`ricochet/`, re-cut to Game Design's 4) was applied in e09dbbbf with World's and Tools' grants, and its scripts are deleted. Hit-stop by weight re-cut (`hitstop2/`, Game Design's 5b and whole ticks) and the run's rare boons (`boons/`) were applied in 83405d99 with Tools' grants, and their scripts are deleted, as is `grant_tools_fight.py` (every schema it held is on main). The air brake's second window (`brake2/`: air sense 10%, the window from the launcher's power, a flight's end clears it, Controls' `brake_ready`) was applied in 982b7b65 with World's, Encounter's and Audio's grants, and the script is deleted. Encounter's three asks (`shared/`: the curve's shared functions, `SimBrake.controlBack`, the camera feed out of the light digest) were applied in c6980e25 with World's arena windows 0 and 1 (`arena-conditions.md` is the review, kept as the record), and the script is deleted. The launch's curve and hit-stop by weight (`feel/`), the forms' working rule (`forms3/`) and the blast cloud's cue and ash (`cata/`) were applied in c09c3bef (2026-10-20) with Tools' schemas, and their scripts are deleted. The pages are `../feel-core.md`, `../forms-core.md` section 8 and `../run-core.md` section 6.

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

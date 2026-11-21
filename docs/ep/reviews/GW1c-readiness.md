# GW1c readiness review: the planet scope

**Who:** Orb's stand-in, as sprint A1's landing reviewer.
**When:** 2026-11-20, evening.
**What was reviewed:** the parks for the planet scope (five sizes, terrain, destruction, clipping), as they stand in the working folder at commit 1f5fc401. The reviewers read at b20020b4, 3f85bbb2 and 1f5fc401; the files the parks touch are the same at all three.
**How:** read-only. Nothing was run in Godot or a browser. Patches were tried with `git apply --check` on scratch copies outside the repo. Every finding is from the files and the run records.

Words used here:
- A **park** is finished work waiting outside main in `docs/<area>/pending/<name>/`.
- A **grant** is a small patch to a file another director owns.
- The **stack** is the parks applied one on top of another.
- The **field memo** is the game's in-memory store of a planet's ground heights.
- The **energy model** is the power rule Orb's 9 November build plays with. Main's data still has it off (`data/fight/power.json:4` `"enabled": false`); GW1a turns it on.
- The **default look** is the picture with "Reduce flashing" on.

The parks: `docs/world/pending/{planet-sizes, gw1c-world, store-parts, crater-tiers, cache-determinism}`, `docs/rendering/pending/{planet-sizes, marks-baked, rows-interp, fore-clamp}`, `docs/architecture/pending/boxkey-gw1c`. The base they stand on, `docs/world/pending/globe-step2`, was read too, because the exit line names it.

Orb's words for this scope, `docs/ep/vision.md:1804`: "I do want the planet, terrain, destruction, clipping all worked on heading towards the A1. Five different planet sizes should be achieved along with this."

## Verdict

**Not ready.** The exit line is: "five sizes selectable, each generates and plays, small, medium and big drawn and measured (tiny and huge per Orb's open answer); feet within 8 units of the drawn ground; the step 2 re-cut landed." (`docs/ep/sprints/A1-sprint.md:50`). Of its parts, only the sim side of medium is proven; six blockers stand, and the whole stack has to be re-cut and re-proven on the tree it will really land on (main after GW1a and GW1b), because every record on file is from main before GW1a.

What is sound: the design of the sizes, medium unchanged when no other size has been played, the box key park, store-parts, and the feet numbers at small, medium and big once rows-interp is in.

## Readiness against the exit line

| Part of the line | Park | Proven, and by which record | Missing | Owner |
| :--- | :--- | :--- | :--- | :--- |
| Five sizes selectable | World `planet-sizes` (data and set-up key); UI `a1-world-menu` and Rendering `world-menu-merge` (the menu row; neither is on the GW1c list) | The data loads and offers five: `SIZES`, `docs/world/runs/planet-sizes/size-check-passes.txt` | No run from the menu to a match at another size on this stack. Tiny and huge are offered with no picture (C-05). No rule for a random quick match's size. LAN is medium only by default, unwritten (C-12) | EP, UI, World |
| Each generates and plays | World `planet-sizes` with Simulation's grant, `gw1c-world` and its fix | Each size ran 600 ticks on planet 7, touch 1, in one process. Rendering's feet runs played small, medium and big for 10 seeds with the memo fix (not hash records) | The World rows for small, medium, big and huge ran on tiny's ground (C-01). One planet of the five. No match to a result. No run across two processes off medium (C-11) | World, Simulation, QA |
| Small drawn | Rendering `planet-sizes` | Feet check passes: 0 of 2,425 over 8, worst 2.2 (`docs/rendering/runs/fd5c1895/sizes-feet-final.txt`) | The only stills of small show a broken picture (C-03). No tile check, render gates or flash reading at small | Rendering |
| Medium drawn, unchanged | Rendering `planet-sizes` | The sim's reference record identical, five ground checks, render gates 20 of 20 (`sizes-tiles-recut.txt`) | A before-and-after picture (C-33) | Rendering |
| Big drawn | Rendering `planet-sizes` | Feet check passes with the skip rule: 2 of 3,315 over 8, worst 8.9 | Stills on record. Tile check and render gates at big. The skip rule explained (C-19) | Rendering, Camera |
| Small, medium and big measured | none | Nothing valid. World's times are marked void by World | Frame, load and memory per size; a build that can take the reading; the number to read against (C-06) | Performance, Rendering, Tools, EP |
| Tiny and huge (Orb's open answer) | World's data offers both; Rendering's diff maps both | Sim only | Tiny: no still, Art's building cap unanswered. Huge: its ground cannot fill as parked (C-05) | Rendering, Art, World, EP |
| Feet within 8 units of the drawn ground | Rendering `feet-ground`, `foot-slice`, `marks-baked` (store-parts form), `rows-interp` | With all four: 0 of 3,046 over 8 at medium, 0 of 2,425 at small, 2 of 3,315 at big (worst 8.9) | The gate itself (C-19). The open tower item (C-04). The lakes (C-20). A default-look side-by-side (C-18) | Rendering, EP |
| The step 2 re-cut landed | World `globe-step2` | `chase_rush_check` 130 of 130, `GLOBE` 67 ok with four controls, parity unmoved, all on def3445a (`docs/world/pending/globe-step2/README.md:28-36`) | It does not apply after GW1a's World pieces (C-07). No run on the data with the energy model on (C-08). Its own step measure fails as shipped, 14 of 40 (C-14) | World, Camera |

Not in the exit line but in the sprint's added scope (`A1-sprint.md:48-49`): craters and trenches drawn where you stand, buildings without the rebound, no fighter sinking into a crater or a building. See C-16 and C-22.

## Stack order and conflicts within GW1c

### What applies on what (checked on scratch copies of 1f5fc401)

| Step | Result |
| :--- | :--- |
| World's stack on today's main: globe-step2 (lint grant, diff, field grant), a-world-01 (diff, two grants), planet-sizes (two grants, diff), gw1c-world, gw1c-world-fix, store-parts, cache-determinism (the after-gw1c-fix form), boxkey | Applies clean, in that order |
| Rendering's field-memo grant, straight after `planet-sizes.diff` | Applies |
| replay-sizes, arc-by-size with its two grants, on that stack | Apply |
| feet_ground, foot_slice, marks_baked.store-parts, rows_interp, sizes_tiles, fore_fix, on that stack | Apply |
| `crater-tiers.diff` on that stack | **Fails** at `tools/world-checks.json:12`. Applies with that one hunk left out |
| `globe-step2.diff` after `a-world-01/data-switches-gw1a.diff` | **Fails**: "patch failed: data/biomes/water.json:63" |
| `globe-step2.diff` after `checks-gw1a/pins-gw1a.diff` | **Fails**: "patch failed: tools/world-checks.json:15" |
| `gw1c-world-fix.diff` after `cache-determinism.diff` (the GW1a form) | **Fails**: "patch failed: sim/world/plan.gd:130" |
| `a-world-01/data-switches-gw1b.diff` after `a-world-01.diff` | **Fails**: "patch failed: data/biomes/world.json:1" |
| VFX's `planet-sizes-meteor/apply.patch` after World's `grant-rendering-meteor.patch` (or the other way round) | **Fails** at `render/vfx/meteor.gd:14`. Each applies alone; only one can be used |
| `marks_baked.store-parts.diff` after tonight's lake fix (`docs/rendering/pending/water-everywhere/water_band.diff`, for GW1b) | **Fails** at `render/core/tile_field.gd:539` |
| Rendering's `water_band.diff` together with World's `lake-places/grant-rendering-tile-water.patch` | **Fails**: both change the same line of `render/core/tile_field.gd` |
| UI's `world-menu.patch` and Rendering's `world_menu_merged.diff` on this stack | Do not apply; they stand on UI's own stack, which was not built here |

So the stack applies only on today's main, where none of GW1a is landed. That is the one base the READMEs checked.

### Files touched by more than one park

| File | Parks |
| :--- | :--- |
| `sim/world/store.gd` | globe-step2, planet-sizes, gw1c-world, store-parts (and marks-baked's older grant, not used with store-parts) |
| `sim/world/field.gd` | globe-step2, planet-sizes, Rendering's field-memo grant |
| `sim/world/craters.gd`, `data/biomes/craters.json` and its schema | globe-step2, gw1c-world, crater-tiers |
| `sim/world/crater.gd` | globe-step2, crater-tiers |
| `sim/world/plan.gd` | gw1c-world-fix, cache-determinism (and lake-places, GW1b) |
| `sim/world/planet.gd`, `size.gd`, `waterrec.gd`, `data/biomes/sizes.json` | planet-sizes, gw1c-world |
| `sim/world/tools/size_check.gd` | planet-sizes, gw1c-world, gw1c-world-fix |
| `sim/world/tools/globe_check.gd` | globe-step2, store-parts |
| `sim/core/field.gd` | globe-step2's grant, planet-sizes' Simulation grant, boxkey |
| `sim/core/sim.gd` | a-world-01's grant, planet-sizes' Simulation grant |
| `tools/world-checks.json` | globe-step2, a-world-01, planet-sizes, gw1c-world, crater-tiers, cache-determinism (and GW1a's pins) |
| `render/core/tile_field.gd` | feet-ground, marks-baked, Rendering planet-sizes (and both lake fixes) |
| `render/core/tile_ground.gd` | marks-baked, Rendering planet-sizes, fore-clamp |
| `render/core/planet_view.gd` | feet-ground, foot-slice |
| `render/vfx/meteor.gd` | World's meteor grant, VFX's planet-sizes-meteor |

### Where the reviewers disagreed, and the order I can defend

The disagreement: one reviewer put Rendering's field-memo grant last, with Rendering's park, as Rendering's README orders it. Two others put it with World's sizes. The second is right: without the grant the sim reads the wrong ground at any size but medium (C-01), so it is a sim fix and must land in the same commit as `planet-sizes.diff`. It applies there (checked).

A second disagreement: one reviewer read crater-tiers as needing `wall-hold-split` first. On my scratch stack it applies without it once its check-list hunk is left out, so that is not a dependency.

The order, each step with its reason. Every step first needs the re-cut in C-07.

| # | Park | Why here |
| :--- | :--- | :--- |
| Before GW1c | `cache-determinism.diff` (GW1a, by its own README:10), a-world-01 (the first step of GW1b, `A1-sprint.md:22`), `foot-slice` (parked "for GW1a"), the lake fix (GW1b) | They are not GW1c's, and GW1c's parks must be cut on top of them |
| 1 | globe-step2: lint grant, the diff, Simulation's field grant | The base. Every other World diff edits files it changes |
| 2 | planet-sizes: Simulation's size grant, `planet-sizes.diff`, the field-memo grant, VFX's `planet-sizes-meteor` in place of World's meteor grant, Simulation's `replay-sizes`. One commit | The memo grant: C-01. VFX's patch: World's would stop VFX's check. replay-sizes: without it a saved match at another size is refused, and the match key follows the last size played (C-09) |
| 3 | gw1c-world, then gw1c-world-fix | They extend the size data and its check |
| 4 | store-parts | It edits the function gw1c-world edits (`store-parts/README.md:40`) |
| 5 | boxkey-gw1c | Stands alone, moves no hash. Any place after step 2 |
| 6 | Encounter's arc-by-size with its two grants | Before any size but medium can be picked with the launch arc on (C-09) |
| 7 | feet-ground, marks-baked in its store-parts form (without `grant-world-store.patch`), rows-interp | The feet line. rows-interp before the sizes, as Rendering's README says |
| 8 | Rendering's `sizes_tiles.diff` with the real feet check's size and split flags | Needs steps 2 and 7 |
| 9 | UI's size row and the `main.gd` merge | Last. This is what puts the sizes in front of a player, so it waits for the pictures |
| Not placed | crater-tiers (split first, C-02); fore-clamp (the EP names its window, C-35) | Neither is in the exit line |

## BLOCKER

### C-01. Two sizes of one planet share one ground in a session

**Park:** `docs/world/pending/planet-sizes` (with `gw1c-world`). The fix sits in `docs/rendering/pending/planet-sizes`.
**Wrong:** the field memo is kept by the planet's seed alone. In one run of the game, the second size of the same planet number reads the ground made for the first. So a match's ground, and its hash, depend on what was played before it. That includes a medium match that names no size, once another size of that planet has been played. World's `SIZES` check plays all five sizes on planet 7 in one process, tiny first, so its 600-tick rows for small, medium, big and huge, its "same setup twice" row for big, and its "medium named equals medium unnamed" row all ran on tiny's ground. The fix exists only as a grant in Rendering's park, and no page under `docs/world` names it.
**Evidence:**
- `sim/world/field.gd:143-144` on main: "if _fields.has(P.seed): return _fields[P.seed]".
- `planet-sizes.diff` changes `sim/world/field.gd` only at `cells()` and `bakeStride()`; no other World or Simulation patch touches the memo.
- `size_check.gd` in `planet-sizes.diff`: "func _setup(nm: String, planet: int = 7, touch: int = 1)" and "for nm in offered: ... _match(_setup(nm), 600)", with the first `WorldPlanet.forget()` only later, in the loader rows.
- `docs/rendering/pending/planet-sizes/README.md:37-38`: "At big, face 5 reads past the end: 42,330 script errors in one run." and "At small the indices stay in range, so it reads the wrong lattice silently."
- `docs/world/pending/gw1c-world/README.md:47` says the opposite: "the others (planet memo, slice memo, store and water grid keys, the field disk cache) carry the size already (checked)".
- Nothing in the shipped game clears the memo between matches: `WorldField.forget()` is called only from `sim/world/planet.gd:457` and `net/bot.gd:165`.
**Fix:** World takes `grant-world-field-size-key.patch` into its own park, in the same commit as `planet-sizes.diff`. Add a `SIZES` row that would have caught it: medium, then big, then small on planet 7 in one process, each hash equal to the same match played after a forget, with the old key as the control that must fail. Re-run `SIZES`, parity and the World checks with the grant, replace the 14 November records, and correct `gw1c-world/README.md:47`.
**Owner:** World (Rendering hands over the grant).
**Limit:** shown by the code and by Rendering's record, not by a hash comparison; nothing was run.

### C-02. The crater-tiers code changes every energy shot's crater on Orb's path, and its README says to land it with GW1a

**Park:** `docs/world/pending/crater-tiers`.
**Wrong:** the code patch, not the data row, changes a shot's crater whenever the energy model is on, with no switch of its own. On the 9 November build a shot's crater energy is the kind's base times `tierEnergy`, model on or off. The patch makes it the base times 12.25 to the fighter's level when the model is on. GW1a closes only when main reproduces the target record made on the 9 November build, bit for bit. Landed "with or before GW1a", this rule would differ from the build the target was made on. Landed in GW1c, it is a hash change and a visible change that the park's pages describe as moving nothing. This blocks this park as parked. Crater width is not in GW1c's exit line, so it does not block the rest.
**Evidence:**
- `sim/world/blast.gd:81` on main, identical in the 9 November build (6a30b4c9): "var E: float = lerpf(...) * float(D.tierEnergy[ti])", with no model branch.
- `crater-tiers.diff`, the `blast.gd` hunk: "if S.powerOn: return e * SimDetMath.pow(SimPower.energyTop, SimPower.level(f))".
- `crater-tiers/README.md:25`: "Land the code with or before GW1a"; `:24` "record it with GW1a's energy target"; `:17` "Nothing moves with the shipped data".
- `docs/ep/sprints/A1-sprint.md:25`: "A-CODE-01 closes when main reproduces the target record bit for bit".
- World's runs in `docs/world/runs/crater-tiers/` are all on main's data, model off in matches.
**Fix:** split the park. (a) The model-off table and its `TIERRATIO` check, which move nothing on Orb's path. (b) The shot rule under the model, behind a data key shipped off, or named as a hash row of GW1c or GW2, never in GW1a. Correct README lines 17, 24 and 25 and `docs/world/crater-tiers.md:24`. Before the shot rule flips: the World checks and Simulation's gates on the post-GW1b data, and a side-by-side of a top-tier shot's crater against the 9 November build.
**Owner:** World, with Simulation for the window.
**Limit:** whether any match in the GW1a target holds a shot crater from a fighter above level 0 was not checked. If none does, the target would not move, but the rule would still differ from the build Orb played.

### C-03. Small is not drawn well, and no still of any size is on record

**Park:** `docs/rendering/pending/planet-sizes`.
**Wrong:** the exit line needs small, medium and big drawn. Stills of all three were made at 19:51 to 19:53 on 2026-11-20, but they sit in a git-ignored folder and no README or run record names them, the build, the seed or the mode. I opened the sheet. Small's row is frame-filling green and grey wedges at every one of five frames, with near-black sawteeth at frames 451 and 601 and the fighters hidden or tiny. Medium (a night village) and big (a snowy forest, split screen) read as normal pictures. The feet check passes at small on the same stack, so the feet check does not see this fault. The tile check, the render gates and the flash checks were run at medium only, though the park's own plan lists the tile check, the feet check and the render gates "at each".
**Evidence:**
- `docs/rendering/img/sizes/sizes-sheet.png` and `sizes-small-t00001/151/301/451/601.png`; ignored at `.gitignore:72`.
- `docs/rendering/pending/planet-sizes/README.md:1`: "stills wait for a capture window"; `:6` "Stills of small and big against medium ... in a capture window".
- `docs/rendering/runs/fd5c1895/sizes-feet-final.txt`, small: "0 over 8 units (0.0%, at most 3%), the worst 2.2".
- `docs/rendering/planet-sizes-plan.md:38`: "Small and big: the tile check, the feet check and the render gates at each".
- `sizes-tiles-recut.txt:1-10` is headed "at medium".
**Fix:** Rendering names the cause of small's picture first: the open, depth, shape and pane render checks and the tile check at small and big, and one still with fore-clamp on the stack, since the teeth look like the fault fore-clamp describes. Then re-take the stills in the default look and write them into the README with their record. The EP does not count small as drawn until a clean still is on record. Add one picture check per size to the gate, because the feet check passes on a broken picture.
**Owner:** Rendering (Tools for the capture window).
**Limit:** this is what the pictures show now. Rendering has not reported them, and the cause is not known.

### C-04. The look gate for the feet parks is still open by the park's own words

**Park:** `docs/rendering/pending/marks-baked`.
**Wrong:** with the feet parks on, a tower behind the fight shows dark gaps between its floors for four frames. The cause is a guess and nothing on record settles it. The form that would land in GW1c (`marks_baked.store-parts.diff` on World's stack) has no side-by-side at all. The feet line depends on this park.
**Evidence:**
- `marks-baked/README.md:64`, under "Owed before it lands": "a tower behind the fight shows dark gaps between floors for frames 108 to 111 (ticks 5,210 to 5,240), with the parks only"; then "So it's drawing, unexplained so far" and "To settle: the tower's footing and drawn base read at those ticks, with and without the parks."
- `docs/rendering/runs/6a30b4c9/feet-orb-side-by-side.txt:14-16`: "likely the groove under the tower".
- No later reading under `docs/rendering/runs`.
- Orb, `docs/ep/vision.md:945`: "gaps between floors without realistic looking supports will make players lose their suspension of disbelief".
**Fix:** Rendering reads the tower's footing and drawn base at ticks 5,210 to 5,240 with and without the parks, fixes or explains it, and re-shoots those frames on the form that will land. The EP looks at the new frames before landing.
**Owner:** Rendering.

### C-05. Tiny and huge would be offered in the menu with no picture, and huge cannot fill its ground

**Parks:** `docs/world/pending/planet-sizes` (the data), `docs/rendering/pending/planet-sizes`, `docs/ui/pending/a1-world-menu`.
**Wrong:** World's data offers all five sizes and UI's row lists every offered size. Rendering's park covers small, medium and big only; no run or still of tiny or huge exists. By reading the code, huge cannot be drawn as parked: its first level of ground is 864 tiles, the store holds 800, first-level tiles are never given up, so 64 are dropped silently and no finer ground can ever load. Art has not answered the building cap for tiny. The design page's fixes for huge's memory and its launch table are in no park (C-12).
**Evidence:**
- `planet-sizes.diff:150` and `:154`: tiny and huge `"offered": true`.
- `docs/ui/pending/a1-world-menu/README.md:15`: "the offered ones in its order: Tiny, Small, Medium, Big, Huge".
- `docs/rendering/pending/planet-sizes/README.md:8`: "Tiny and huge when Orb's answer comes".
- `render/core/tile_field.gd:19`: "const POOL: int = 800", left as it is by `sizes_tiles.diff`, whose `level0_for` gives "huge 12" (6 x 12 x 12 = 864).
- `tile_field.gd:339-345`: a layer is reused only when "((_keys[q] >> 3) & 7) > 0"; `:559-562` "if slot < 0: _job_key = -1 ... return"; `:424` "if _free_slot() < 0: break".
**Fix:** until each has a passing picture, World sets `offered` false on tiny and huge (reachable by set-up key only), or UI shows only sizes with a passing picture. Rendering sizes the store from the planet, or lets first-level tiles be reused at huge, and runs the tile and feet checks at both. The EP puts the sharp form of the open question to Orb with a still of each: tiny and huge play in the rules but have no finished picture; do they appear in the A1 menu?
**Owner:** World (data), Rendering (store and stills), UI (row), EP (the question).
**Limit:** the 864-against-800 fault is read, not run.

### C-06. Nothing is measured

**Park:** none. The only build that can load a size is a scratch export described in `docs/rendering/pending/planet-sizes`.
**Wrong:** the exit line says small, medium and big are "measured". No frame, load or memory reading that is valid by the sprint's rule exists for small or big, and none for medium on the 9 November build or later. World's start and tick times are marked void by World. The browser cost of re-baking ground tiles when a mark is made, which marks-baked says is owed, is not on record. Big loads four times medium's first-level tiles before a match (216 against 54), also unread. There is no number in the sprint to read against.
**Evidence:**
- `A1-sprint.md:43`: "the frame cost of each is read in a quiet window"; `:69` "no frame-rate or loading reading while the machine is busy, since such a reading is void".
- `docs/world/pending/planet-sizes/README.md:23`: "Frame cost per size | not measured: the machine was shared".
- `docs/ep/proposals/planet-a1-design.md:7`: "No frame, load or memory reading exists for any size but medium, and none on the 9 November build or later".
- `docs/production/milestone-rows.md:89-91`: A-PERF-04, -06 and -07 "not started".
- `docs/rendering/pending/planet-sizes/README.md:20`: the size word is "not a park"; `:7` lists "Performance's readings at small, medium and big on the same export" as next.
- `docs/rendering/pending/marks-baked/README.md:62`: "the probe counts rebakes ... but times nothing".
- `docs/perf`: no file names a planet size or any of these parks.
**Fix:** Performance parks a bench that takes a size and runs on the desktop build. Until that build exists, Rendering moves its export and size word out of scratch into a park, with the build recipe, so a reading can be repeated. One quiet-window run each for small, medium and big, in the default look: frames over a whole match, cold and warm start to control, memory, and the tile re-bake with marks-baked on; saved under `docs/perf/runs/<sha>/`. The EP writes the numbers each is read against and whether they report or gate.
**Owner:** Performance (bench and readings), Rendering and Tools (the build), EP (the numbers).

## MAJOR

### C-07. The stack does not apply in the sprint's own order

**Parks:** `docs/world/pending/{globe-step2, gw1c-world, a-world-01, cache-determinism, crater-tiers}`, `docs/rendering/pending/marks-baked`.
**Wrong:** see the apply table above. Every sizes park stands on `globe-step2.diff`, and that diff stops applying once either of World's GW1a pieces is on main. `gw1c-world-fix.diff` stops applying once `cache-determinism.diff` is on main, and that park is GW1a's by its own README. The GW1b mode flip does not apply to the file `a-world-01.diff` creates. `crater-tiers.diff` does not apply on the stack as cut. Found while writing this report: the lake fix parked on 2026-11-20 for GW1b changes `render/core/tile_field.gd:542`, after which `marks_baked.store-parts.diff` no longer applies; and Rendering's and World's lake patches change that same line and cannot both be used.
**Evidence:** the apply table; `docs/world/pending/cache-determinism/README.md:10` "Land the first on HEAD with GW1a"; `docs/architecture/pending/frame-gw1a/README.md:21` "On the rebuilt GW1a stack (b09d705)"; `docs/world/runs/gw1c-world/README.md:3` "Scratch trees of HEAD def3445a".
**Fix:** re-cut `globe-step2.diff`, `gw1c-world-fix.diff`, `data-switches-gw1b.diff`, the check-list hunk of `crater-tiers.diff` and `marks_baked.store-parts.diff` on the EP's tree after GW1a and GW1b. Delete `cache-determinism.after-gw1c-fix.diff`, which can no longer be the form used. The EP picks one of the two lake patches. One apply order for the whole GW1c stack, across owners, in one page.
**Owner:** World; Rendering for marks-baked; EP for the page and the lake pick.

### C-08. Every proof for the World stack was run on main as it was before GW1a

**Parks:** `globe-step2`, `gw1c-world`, `store-parts`, `crater-tiers`.
**Wrong:** the records are from trees of def3445a or 20713b02, with the energy model off. GW1c lands after GW1a and GW1b, when a match that names no switch plays the model. None of the stack's new checks sets the model, so they will follow the data's default onto a path they have never run on. By reading, one `GLOBE` row goes red there: it needs an ordinary blow to be capped at 600, and the same patch lifts that cap under the model. The only `chase_rush_check` run with step 2 on file is on the old data; on Orb's data Camera recorded that check 19 of 130 red before its own pins.
**Evidence:**
- `globe-step2/README.md:5`: "Cut on HEAD 20713b02 ... re-checked on def3445a".
- `sim/core/power.gd:118`: "S.powerOn = su.get(\"power\", on_) == true".
- `globe-step2.diff:925`: the check's set-up is `{"intro": false, "planet": 7, "touch": 1, "planetGen": 3}`, with no "power" key; the same holds for `globe_audit`, `size_check` and `crater_flatten_check`.
- `globe-step2.diff:370`: "var rcapH: float = R_MAX if (special or S.powerOn) else ORD_R_MAX" against `:1079` "an ordinary blow on a %.0f-radius special crater supersedes nothing (it could dig only 600)".
- `docs/camera/pending/gw1a-pins/README.md:16`: "`chase_rush_check` | 19 of 130".
**Fix:** after the re-cut in C-07, re-gate the whole stack on the post-GW1b tree: the World checks with `--run`, `GLOBE` and `CRATERFLATTEN` with the model on, Camera's `chase_rush_check` in its GW1b form, the 40-seed audit at both groove settings, parity. Each row that assumes the ordinary cap is run both ways with its class written down. Save the records under `docs/world/runs/`, named for the tree.
**Owner:** World (Camera for the chase run).
**Limit:** the red `GLOBE` row is read, not run.

### C-09. Parks the sizes cannot work without are not on the GW1c list

**Parks, all outside the list:** `docs/architecture/pending/replay-sizes`, `docs/director/pending/arc-by-size`, `docs/vfx/pending/planet-sizes-meteor`, `docs/ui/pending/a1-world-menu`, `docs/rendering/pending/world-menu-merge`.
**Wrong:** no page gives one order for them (each park states only its own place).
- Without replay-sizes, a saved match at another size is refused on a PC that last played medium. The match key is read from whatever size the process last bound, and nothing puts the size back when a match ends, so a medium replay or a medium LAN handshake after a sized match would also be computed at the wrong size. That second case is a sound reading of the code, not a recorded run.
- Without arc-by-size, the launch arc scales with the planet's lap: twice as high on big, four times on huge. This bites only once the arc is on; it is off in main's data (`data/director/launch.json:111`) and Encounter's `director-rows` park turns it on.
- World's README still lists its own meteor grant, which VFX replaced; the two cannot both apply.
- Without UI's row and the `main.gd` merge there is no way for a player to pick a size.
**Evidence:**
- `docs/architecture/pending/replay-sizes/README.md:8`: "refused as \"data\" before its first tick".
- `docs/sim/runs/bf6c4538/replay-sizes/summary.txt`: before the fix "SIZE REPLAY PROBE: 2 of 2 sizes fail".
- `docs/director/pending/arc-by-size/README.md:11`: "Big ×2 and huge ×4. The meteor would peak at 32,800 and 65,600 units, above the 24,000 flight ceiling."; `sim/director/arc.gd:139` "return SimConst.W / float(cfg().wholeRing)".
- `docs/world/pending/planet-sizes/README.md:31`: "speeds, launches and bodies are absolute".
- `docs/vfx/pending/planet-sizes-meteor/README.md:3`: "removing the constant would have stopped the check".
- `arc-by-size/README.md:59`: "The self-test has 2 failures ... World's new `biomes-sizes` and `biomes-world` schemas have no invalid cases yet".
**Fix:** the EP adds these parks to the GW1c list with one written order (see the order table). World's sizes never land without replay-sizes in the same commit. Simulation adds a parity row for the reverse case: a medium replay verified after a tiny match. World corrects README line 31 and drops its meteor grant in favour of VFX's. Tools adds invalid cases for the two new schemas.
**Owner:** EP (list and order); Simulation, Encounter, UI, VFX (their parks); World (README); Tools (schema cases).

### C-10. What the size data says is in no cache key

**Parks:** `planet-sizes`, `gw1c-world`.
**Wrong:** the planet's saved file holds the places, and the places file holds the laid buildings with their capped heights. Both are keyed by the column count alone. The READMEs and Game Design's page invite edits to exactly these numbers. After such an edit, a PC that has played that size before reads the old places back and a PC with an empty cache builds the new ones. Both carry the same size table, so they agree at the start and part at the first checkpoint. The disk cache is on as shipped.
**Evidence:**
- `planet-sizes.diff:486-487`: "var size: String = \"\" if SimConst.PLANET_NC == SimConst.PLANET_NC_MEDIUM else \"|cols %d\" % SimConst.PLANET_NC".
- `gw1c-world-fix.diff`, `_sizeTag`: "\"|cols %d\" % SimConst.PLANET_NC".
- `sim/world/planet_cache.gd:93-99` restores "P.n = np ... P.kind ... P.px" from the file; its only witness is grid heights (`:82-86`).
- `sim/world/planet.gd:52-57`: `dataHash` does not read `sizes.json`.
- `data/biomes/field.json:24-28`: the cache is enabled.
- `docs/design/planet-sizes.md:19`: "raise that size's town count first".
**Fix:** put a hash of the size's own row of `sizes.json` into the planet disk key, the places key and the plan memo key in place of the bare column count; medium keeps its keys. Add a `SIZES` row: change a place count through a test override, both keys change, the old key as the control.
**Owner:** World.

### C-11. "Each generates and plays" rests on one planet, ten seconds, one process

**Parks:** `planet-sizes`, `gw1c-world`.
**Wrong:** `SIZES` plays each size on planet 7, touch 1, for 600 ticks of computer against computer, in one process, and asserts only that the match reached tick 600 with finite fighters. With GW1b the first match is planet 7 at touch 3 and a quick match draws from five planets and three touches; none of those was stepped at any size but medium. No match at another size has been played to a result. No run across two processes names a size. What does exist beyond the `SIZES` rows: huge is played 5 ticks on its own ground after the check's forget; big on planet 12 is loaded and started but not stepped; Simulation's probe recorded and replayed big and tiny in one process; Rendering's feet runs played small, medium and big for 10 seeds with the memo fix, but those are not hash records.
**Evidence:**
- `docs/world/pending/planet-sizes/README.md:46`: "Only planet 7 (touch 1) was played at every size, and planet 12 touch 2 at big through the loader: each size's own pool of planets that generate and play is a later check".
- `a-world-01.diff:254-255`: `"fixed": { "planet": 7, "touch": 3, "planetGen": 3 }`, `"pool": [7, 12, 3, 13, 17], "touches": [1, 2, 3]`.
- `gw1c-world.diff`, the 75-spawn row: only `WorldPlanet.make(pl)` and `WorldPlanet.touchPoint(P, tc)`, no match.
- No file under `tools/`, `qa/` or `sim/core/tools/` contains `planetSize`.
- `docs/design/planet-sizes.md:19`: "QA reads places reached and the share of buildings fallen, by size"; nothing under `docs/qa` names a size.
**Fix:** after C-01's fix, in a quiet window at below-normal priority: each offered size on the fixed planet at touch 3 and on each quick-match planet and touch, 600 ticks or more, each size twice from a cleared memo; one full computer match to a result per size; one replay across two processes per size. File the hashes. QA makes the per-size read Game Design's ruling asks for.
**Owner:** World, with Simulation for the two-process row; QA.

### C-12. Four things the design page wants before a size is offered have no park and no reading

**Park:** none.
**Wrong:**
1. Ground memory. The memo keeps up to three planets' ground in total, and the field-memo grant keeps that line. The design page's worst case at huge stands, and it names World for the fix; no park does it.
2. Huge's launch ceiling table still fills over about half a minute; no park touches it.
3. LAN plays medium only because its fixed set-ups name no size. Nobody has written that down as the rule for A1. Netcode's price for big and huge is paper only.
4. Camera: see C-13.
The frame reading is C-06.
**Evidence:**
- `sim/world/field.gd:167`: "while _fields.size() >= 3:".
- `docs/ep/proposals/planet-a1-design.md:65`: "The ground lattice as kept today (three planets) ... 182 MB"; `:69` "Fix, for World: keep one planet's lattice from big upward".
- `data/fight/swing.json:78` `"warmCeil": 8` and `sim/core/field.gd:500` "_ceilStep(S, int(d.warmCeil))"; no park under review mentions either.
- `net/lan.gd:30`: `SETUP` has `"planet": 7` and no `planetSize`.
- `docs/net/planet-sizes-net.md:3`: "This is paper only: nothing was built or run"; `:9` "Today they name none, which is medium".
**Fix:** the EP names a park for each. World keeps one planet's ground from big upward and fills the ceiling tiles near the fighters first, or during loading. One line in the sprint: LAN is medium for A1. When a LAN size is wanted, Netcode's bench and the state check are read at medium and big in Performance's quiet window.
**Owner:** EP to assign; World, Netcode.

### C-13. Camera has no park and no reading for any size but medium

**Park:** none.
**Wrong:** three of the peak-launch shot's limits scale with the planet's lap, through `ring_k` (the lap over a fixed 153,600): the shot's cap (`split_rig.gd:5260`), its landing width (`:5219`, `:5224`) and the reveal's cap (`:5354`). That factor is 0.27, 0.53, 1, 2 and 4 from tiny to huge. It scales limits, not the whole frame, so "framed twice as wide on big" is too strong; but the shot can go twice as wide on big before its cap, and is held to about half on small. Encounter fixed the same assumption for the launch arc. No Camera page names a size.
**Evidence:**
- `render/camera/camera_params.gd:357`: "const PEAK_RING: float = 153600.0 # the ring those widths are for: a smaller ring scales them".
- `render/camera/split_rig.gd:5258-5260`: "var ring_k: float = SimConst.W / CamParams.PEAK_RING" and "var top: float = float(CamParams.PEAK_LADDER[tier - 1]) * ring_k"; `:5353-5354` the same for the reveal.
- `docs/ep/proposals/planet-a1-design.md:121` lists "Camera has looked at big and huge" as a condition.
**Fix:** Camera runs its launch-shot and chase rows at small and big and says whether the limits should follow the arena or stay fixed, with a side-by-side for medium showing no change. It also answers C-19's question about fighters outside every pane.
**Owner:** Camera.

### C-14. Whether a slider is thrown into the air by the end of its own trench is untested, and the record that says "no" cannot answer it

**Park:** `docs/world/pending/globe-step2` (and `docs/ep/proposals/planet-a1-design.md` section 4, the stand-in's own page).
**Wrong:** World's log counts a scratch print in `WorldSlide.step`. A shipped match never calls that function: contact is on, so a launched body's skid is `WorldContact`'s, which has its own leave test. Zero printed lines is what that print gives in any match. The stand-in's design page made the same slip by citing `slide.gd`. No park touches the leave test, the test the design asked for is in no park, and the trial of the two candidate fixes has no owner. Step 2 as shipped also fails its own step measure.
**Evidence:**
- `docs/world/runs/globe-step2/slope-test-log-chase-rush-rows.txt:2`: "The slide's two slope tests are in sim/world/slide.gd step"; `:4-5` "SLIDEDBG lines 0".
- `sim/core/fighter.gd:106-110`: "if S.contactOn: WorldContact.stepFighter(S, f, dt)" then "return", before `WorldSlide.step`.
- `data/biomes/contact.json:4`: `"enabled": true`.
- The played path's test: `sim/world/contact.gd:821-830`.
- `docs/ep/proposals/planet-a1-design.md:148-150` cites `sim/world/slide.gd:121-141`.
- `globe-step2/README.md:22`: "As shipped (off): 14 of 40 matches over 6".
**Fix:** redo the log on the path that plays: count `contact.gd`'s leave events by cause on the skid ticks of the four failing chase rows and of a plain skid on flat ground, model on and off, with one row where the print is known to fire. Add the test as a World check. Name the owner of the trench trial, or say it waits for step 3. The stand-in corrects section 4 of its page.
**Owner:** World (with Camera); the stand-in for the design page.

### C-15. The level crater floor is not the pure read its README says once there are two craters

**Park:** `docs/world/pending/gw1c-world` (the `flatten` switch, shipped off).
**Wrong:** the dig's own depth rule reads the flattened height. So with the switch on, a second crater near a flattened one is stored at a different depth, or refused, and the store and its hash differ from the switch off. Where two bowls overlap, the floor is taken from one crater only, so the ground can step along the older crater's lip. The check covers one crater. The README proposes flipping it in GW1c. With the switch off, as parked, nothing moves. This is the fix for the humps Orb saw in a crater, so GW1c as parked does not fix them.
**Evidence:**
- `gw1c-world/README.md:14`: "It is a **read, not a record** (the store and its hash are the same on and off)"; `:29` "flip it only after their look gate and a bake read".
- `gw1c-world.diff:219-226`: "if wk > fw: fw = wk; fk = k" and "sum += fw * (_centreGround(S, ent, fk) - _fieldH(S, qx, qy, qz))", inside `heightDeltaX`.
- `globe-step2.diff:466-470`: the dig reads "relief = WorldGlobe.relief(S, qg, RING_K * R, _gSup)", and relief reads `heightDeltaX` (`:856`).
- The check's hash row compares states that each hold one dig (`gw1c-world.diff:467-494`).
**Fix:** before any flip, add rows for two overlapping bowls on hills, a trench through a flattened bowl and a crater at a lake shore. Either blend the centres by weight or make the dig read the unflattened height, and say which. Correct README:14. Keep the switch off in GW1c unless those rows and Rendering's look gate exist. The EP says whether the flatten flips in GW1c or is carried by name.
**Owner:** World; Rendering for the look gate; EP for the window.
**Limit:** read from the code, not run.

### C-16. The building rebound is in the sprint's added scope and nothing in GW1c touches it

**Park:** none in GW1c (`docs/world/pending/wall-hold-on`, `wall-hold-split`).
**Wrong:** the rebound fix is a data row scheduled for GW2. The one real fault that stands, a building's memory doing nothing under the energy model, is only held as a ceiling in GW1a's pins; its owed fix has no park. QA's city read is not on file. Orb's own answer on the lodged fighter is still to wait until they play it. The wall-hold check pins no longer apply once GW1a's pins are in. This is a gap against the added scope, not against the exit line, which does not name the rebound.
**Evidence:**
- `A1-sprint.md:48`: "buildings breaking at every tier without the \"ping pong\" rebound Orb saw".
- `docs/world/pending/wall-hold-split/README.md:8`: "This is the GW2 data row".
- `docs/world/pins-and-the-model.md:19`: "`wall-hold-on`'s `repeatMarks` 2 is inert on Orb's path until it lands"; `:32` "memory-under-model (World)"; no folder of that name exists.
- `qa/known-bugs.md:241`: "QA's city read waits for it".
- Orb, `docs/ep/vision.md:1687`: "disappointed to see them bounce back to the strip like a 'ping pong ball'"; `:1862` "[x] Wait until I play it".
- Scratch check: after `pins-gw1a.diff`, `wall-hold-pins.diff` fails at `wall_hold_check.gd:126`, `brunt_check.gd:176` and `repeat_check.gd:60`.
**Fix:** the EP writes down that the rebound is not in GW1c and which window carries it. World parks the memory fix and re-cuts the wall-hold pins on GW1a's pins. QA does the city read on a scratch copy. Tools makes the private build with the row on for Orb to play; main flips only on Orb's word.
**Owner:** World; QA for the read; EP for the scope line and Orb's build.

### C-17. Destruction has no ruling and no measurement by size

**Parks:** `gw1c-world`, `planet-sizes`.
**Wrong:** crater sizes are fixed distances while the planet shrinks. The largest bowl allowed is 8,320 units and the meteor's cap is 6,100, against tiny's radius of 6,519. A top-tier special blow under the model is about 3,735, over half of tiny's radius. Game Design capped building height and the authored launch curves for tiny and small and said nothing on craters, trenches or the beam's groove. The size check digs only two small craters, on huge. So "each generates and plays" says nothing yet about whether a strong fight wrecks a tiny or small planet, which bears on Orb's open answer about tiny.
**Evidence:**
- `sim/world/crater.gd:16`: "const R_MAX: float = 1040.0 * WS" (WS is 8); `:17` "SPECIAL_E_MULT: float = 9.0 ... (3 times the radius)".
- `data/biomes/craters.json:9`: `"rMax": 6100.0`.
- `docs/world/planet-sizes.md:11`: tiny's radius 6,519, small's 13,038.
- `docs/world/crater-tiers.md:9`: "a top-tier one's 1,245".
- `docs/design/planet-sizes.md` has no mention of craters or destruction.
**Fix:** Game Design rules whether the crater cap, the meteor's cap and the store's floor scale with the radius on tiny and small. World adds `SIZES` rows: a top-tier special blow and a meteor landing on tiny and small leave a bowl under the ruled share of the radius, and the 40-seed audit runs once per size. Tell Orb the result with the tiny question.
**Owner:** Game Design (ruling), World (rows).
**Limit:** the bowl sizes against the radius are arithmetic from the constants, not a record.

### C-18. No side-by-side in the default look is on record for any of the four picture parks

**Parks:** `docs/rendering/pending/{marks-baked, rows-interp, planet-sizes, fore-clamp}`.
**Wrong:** the two side-by-sides for marks-baked and rows-interp were made through the clip tool, which films with Reduce flashing off, and the grooves these parks now draw under the fighters are drawn differently in the default look. The marks-baked one is of the older cut on the 9 November tree, not the form that will land. Rows-interp's is against the feet build, not the reference. Fore-clamp's sheet is main against the change on a test scene, mode not stated. Planet-sizes has none, and its export's start line passes no mode.
**Evidence:**
- `tools/preview/blackbox-clip.mjs:47`: `window.__flashcap.start("ai", { reduced: false, seed: ...})`.
- `render/core/planet_view.gd:2105`: "The grooves' calm form, under reduced flashing or reduced motion ... a fainter glow and char".
- `docs/rendering/runs/6a30b4c9/feet-orb-side-by-side.txt:2`: "through Tools' blackbox-clip".
- `docs/rendering/pending/rows-interp/README.md:31`: "Left is the feet build".
- `docs/rendering/pending/planet-sizes/README.md:20`: `window.__flashcap.start("beamduel", {seed: 12345})`.
**Fix:** Tools gives the clip tool a mode flag that defaults to the default look. Rendering re-shoots one side-by-side per park in the default look, on the landing stack, against the 9 November build at the same ticks, and sets the mode in the export's start line.
**Owner:** Rendering (re-shoot); Tools (the flag).

### C-19. The feet check is not yet the gate the exit line needs, and big passes only through an unexplained skip

**Parks:** `docs/rendering/pending/marks-baked` (the check), `docs/rendering/pending/planet-sizes` (the scratch copy with size and split).
**Wrong:**
- The check that lands passes at 3% of samples over 8 units and nothing over 25. That is looser than "feet within 8 units", and looser than the 0.5% and 12 that Rendering's README says the EP set; no decision record of that number was found, and no park puts it in the file.
- It is in no gate list and not in CI. It reads medium only, without the split screen; the size and split flags exist only in a scratch copy.
- The scratch copy skips a fighter outside every drawn pane. The README explains two ticks on big's seed 2. The rule drops 159 of 3,474 samples at big and 190 of 3,236 at medium, and it removed the failing samples on big's seeds 6 and 8 as well. Without the skip, big's worst is 14.4, over 12.

| Size | Before the skip (with rows-interp) | After |
| :--- | :--- | :--- |
| Big | 7 of 3,474 over 8, worst 14.4 | 2 of 3,315 over 8, worst 8.9 |
| Medium | 3,236 samples read | 3,046 read: 0 over 8, worst 1.6 |
| Small | none skipped | 0 of 2,425 over 8, worst 2.2 |

**Evidence:**
- `marks_baked.store-parts.diff:314-316`: "const OVER: float = 8.0", "const WORST: float = 25.0", "const SHARE: float = 0.03".
- `docs/rendering/pending/planet-sizes/README.md:55`: "the ratchet the EP set for when it lands: at most 0.5% over 8, nothing over 12" against `docs/rendering/pending/rows-interp/README.md:27` "That's the EP's call."
- `docs/rendering/pending/planet-sizes/feet_check_size.gd:127-129`: "if bd > pane.cam_rig.half_width(1280.0) * 1.25: off_pane += 1 / continue".
- `planet-sizes/README.md:44`: "for two ticks while the split opened, one fighter was 31,700 units from the only pane's camera".
- `docs/rendering/runs/fd5c1895/sizes-tiles.txt:210-219` and `sizes-feet-final.txt:47-56`.
- No match for the feet check in `.github/workflows/ci.yml` or `docs/ep/gate/run-gate.sh`.
**Fix:** Rendering adds one patch: the real feet check with size and split flags, the pass line at the EP's number, and a runner entry for small, medium and big. The record lists, for each skipped sample on big's seeds 2, 6 and 8 and medium's seed 1, the tick, the fighter and the distance to the nearest drawn pane's camera. If a fighter really is off every pane for most of a second in play, that goes to Camera through the EP; if not, the skip comes out. The EP writes the number down as a decision, adds the check to the gate, and restates "within 8 units" with its allowance.
**Owner:** Rendering (the check); Camera (the off-pane samples); EP (the number and the line's wording).

### C-20. Fighters stand in the air over undrawn lakes on the stack GW1c lands on

**Parks:** found by `docs/animation/pending/water-tile-check`. Answered on 2026-11-20, after the reviewers read, by `docs/rendering/pending/water-everywhere` and `docs/world/pending/lake-places`.
**Wrong:** with GW1a's data, lakes near towns drew no water and fighters stood up to 681.5 units above the drawn ground, against the line's 8. The feet check cannot see it: it samples only a fighter within 1 unit of the sim's ground, and a lake's floor is a separate read. The two new parks answer it for GW1b, but neither is gated or landed, Rendering's own page says "GATES PENDING", the two patch the same line and cannot both apply (C-07), and with Rendering's line alone 14 lake places are still up to 59.2 units off.
**Evidence:**
- `docs/animation/pending/water-tile-check/README.md:16`: "the GW1a stack | FAILED: dry 5 beyond 6 (32.6 above), lake 17 of 17 beyond 6, up to 681.5 above the drawn ground".
- `feet_check_size.gd:112`: "if absf(foot - WorldTerrain.groundY(S, x)) > 1.0: continue".
- `docs/rendering/pending/water-everywhere/README.md`: "14 beyond 6, up to 59.2 above and 35.6 below: every lake drawn" and "GATES PENDING".
- `docs/world/pending/lake-places/README.md`, the result table: with both fixes "1 beyond 6, up to 0.0 above and 12.9 below".
**Fix:** the EP picks one lake patch and gates it in GW1b. Animation's `water_tile_check --strict` joins the gate list beside the feet check and is run at small and big. The feet check also samples a fighter standing on a water floor, against the drawn water.
**Owner:** EP (routing and the pick); Rendering and World (the fix); Animation (the check).

### C-21. No measured flash reading exists for three of the four look changes

**Parks:** `marks-baked`, `rows-interp`, `planet-sizes`.
**Wrong:** the render gates' two flash checks did pass at medium on the stack for marks-baked's store-parts form and for planet-sizes. What is missing is a measured reading through Tools' capture and analyser, in both modes, for marks-baked, rows-interp and planet-sizes, and anything at all at small or big. Fore-clamp has before-and-after readings in both modes, on a test scene; its standard-set reading is owed by its own README.
**Evidence:**
- `docs/rendering/pending/marks-baked/README.md:63`: "Also the flash readings on the tile ground (wave 2)."
- `docs/rendering/pending/rows-interp/README.md:35`: "It isn't measured."
- `docs/rendering/runs/fd5c1895/sizes-tiles-recut.txt:10`: "flashreg exit 0 ... flash exit 0", in a run at medium.
- `docs/rendering/pending/fore-clamp/README.md:58`: owed "The flash on the standard set".
**Fix:** Rendering, with Tools' capture, takes the standard set's readings in both modes on the landing stack with each look change on, and one clip at small and big, and files them beside each park before the EP's gate.
**Owner:** Rendering.

### C-22. The exit line has no clause for half of the added scope, and the tracker still books the work twice

**Park:** the exit line itself (`docs/ep/sprints/A1-sprint.md`, `docs/production`).
**Wrong:** the second review asked for an exit block for the planet scope. A line now exists, but it has no clause for craters and trenches drawn, the building rebound, or a fighter sinking into a crater or a building, all named in the added scope. The tracker shows the step 2 re-cut as not started beside the same work booked for GW2, and change control still says there are four hash windows.
**Evidence:**
- `A1-sprint.md:48-49` against the line at `:50`.
- `docs/production/done-tests.md:49`: "terrain, destruction and clipping still need theirs ... still need the EP's confirmation".
- `docs/production/milestone-rows.md:174`: ADD-A1-02 "not started", beside `:355` A-WORLD-03 "GW2".
- `docs/production/change-control.md:12`: "There are four (GW1 to GW4)"; `:40` "No, apart from the riders already listed for GW1b".
**Fix:** the EP adds one countable test per missing item, each marked must-pass or carried by name. Production Operations moves the rows into A1, removes the duplicates, corrects ADD-A1-02's status and updates change control.
**Owner:** EP; Production Operations.

## MINOR

Each was checked against the files by the report writer.

| # | Park | What is wrong | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| C-23 | `planet-sizes` | Colossal is off only in the menu. A set-up or a replay that names it plays 38,400 columns, the size both pages call unproven | `planet-sizes.diff:85`: "if not _d.sizes.has(n):" is the only test in `nameOf`; `docs/world/planet-sizes.md:15`: "it is unproven" | `nameOf` falls back to medium for a size whose `offered` is false; a `SIZES` row plays colossal and expects 4,800 columns | World |
| C-24 | `planet-sizes` | The store's grid key leaves a margin of two boxes past the radius, but a record is listed out to twice its own radius. At huge, a crater wider than about 1,280 units near an axis point lists past the margin, and from about 2,300 its key equals a real box's on the far side. No wrong height was found from it, but the comment's claim is not true | `planet-sizes.diff:443-453`: "so no two boxes share a key" and "+ 2"; `sim/world/store.gd:73`: "var reach2: float = S.store[o + 4] * REACH_R" (2.0). At huge the offset is 98, so key(0,100,0) equals key(1,-96,0) | Use Simulation's fixed packing (20 bits an index) in the store's and the water records' keys; add a `SIZES` row with the largest crater at an axis point of huge | World |
| C-25 | `planet-sizes` | Several distances in the sim are a share of the lap, so they change with the size although the README says only the lap does. One value is checked once at load against whatever size is bound then | `sim/core/swing.gd:535` "SimConst.W * 0.125"; `sim/director/outside.gd:133` "SimConst.W / 6.0"; `sim/director/launch.gd:974` and `sim/world/epoch.gd:357` "SimConst.W * 0.25"; `sim/core/campaign.gd:59` with `data/fight/campaign.json:24` "ringCols": 2400, over tiny's 1,280 (the campaign is off today) | World lists these for Game Design, who rules each; the campaign's bound is read when a run starts | World, Game Design |
| C-26 | `store-parts` | The README says two things about what `parts` returns, and its golden claim has no record file in its runs folder | `store-parts/README.md:12` "[sum, groove, lip, bowls]" against `:23` and `:39` "a PackedFloat64Array of three"; the diff returns four; `docs/world/runs/store-parts/` holds seven check logs and no golden or parity file | Correct lines 23 and 39; file one before-and-after hash of a round-planet match with craters and a trench | World |
| C-27 | `cache-determinism` | Listed with GW1c but GW1a's by its own README. It changes play as well as the cache for matches with plans everywhere on, and its "golden unchanged" has no record file | README:10 "Land the first on HEAD with GW1a"; `:19` "golden \| unchanged"; `:23` "a replay of it will not verify"; no parity or golden file in `docs/world/runs/cache-determinism/` | Move it to the GW1a list; file the parity record taken on the GW1a stack; drop the second form | World, EP |
| C-28 | `globe-step2` | The inland sea stays. The fix is built and off, so after GW1c a deep hole below the shore line still reads as sea. The flip waits on Rendering's pool and a look gate with no date | README:23 "with it off it reads as sea 46.8 deep, which is the inland sea in play today"; `docs/world/destruction-a1.md:8` "it needs Rendering's pool and a look gate before it flips" | The EP names the window and briefs Rendering; until then the sprint page says the inland sea is still in the A1 build | World, Rendering, EP |
| C-29 | `globe-step2` | Five of `GLOBE`'s 67 passing rows cannot fail or pass on the weaker side of an "or" | `globe-step2.diff:1156` "ok(true, ...)"; `:1340` "ok(more != null or true, ...)"; `:1297`, `:1337`, `:1342` | Replace the two constant rows with real assertions and tighten the three, before the flood switch is flipped on this check | World |
| C-30 | `crater-tiers`, `globe-step2` | The crater ratio is asserted as a formula, not as a mark: no crater is dug in the model-on rows. Nothing in CI asserts that a base-tier fight does not wreck the planet; the one tool that reads the ground after whole fights is left out of CI | `crater-tiers.diff:224-225`: "radiusOf(WorldCrater.impactEnergy(sp, tier, S), true)"; `globe-step2/README.md:22` "14 of 40 matches over 6" | Add one row that digs at base and top tier; add a short base-tier row | World |
| C-31 | `gw1c-world` | On tiny and small the height cap is applied after people are given to buildings, and a building's share of people is weighted by its height. A capped tower keeps the tall tower's people | `gw1c-world.diff:91-93`: `assignPeople(...)` then "b.h = WorldPlanetSize.capHeight(b.h)"; `sim/world/settlements.gd:273` | Cap before `assignPeople`, or say in the README it is on purpose | World |
| C-32 | `crater-tiers` | The data row has no picture on record, and the feet records' stack leaves crater-tiers out. On Orb's path the row is not read (the energy model decides), so this matters only for the shot rule in C-02 and for a model-off match | `docs/world/crater-tiers.md`: "Energy model on \| No tier table; the model decides"; `docs/rendering/runs/fd5c1895/marks-baked-store-parts.txt:2-13` | Rendering re-runs the feet check on the full stack; the picture goes with C-02's side-by-side | World, Rendering |
| C-33 | Rendering `planet-sizes` | "Medium is byte-identical" is proven for the sim's record and the checks, not for the picture. The plan asks for a side-by-side | README:34; `docs/rendering/planet-sizes-plan.md:43` "a side-by-side for medium showing nothing changed" | One pixel comparison of medium with and without the diff, default look; reword the README | Rendering |
| C-34 | Rendering `planet-sizes` | No record shows the sim's hashes at small or big are the same with the tile ground drawing as without it. At tiny and small the tile fill calls World's sampler on the sim's own kept field, which writes its last-sample values. The determinism gates ran at medium only | `sizes_tiles.diff:90-96`: "WorldField.sample(_F, dp[0], dp[1], dp[2], 1)" then "h = _F.oh"; `sim/world/field.gd:349-355` writes `F.oh`, `F.ob`, `F.ofine` | Run the determinism gate at small and big with the tile ground on and off; file the hashes | Rendering |
| C-35 | `fore-clamp` | Its window and its proof on the landing stack are unclear. It was cut on an older stack, leaves a known fault half fixed, and its claim that planet 7 is unchanged rests on stills | README:1 "(planets 12 and 17, GW1b's quick-match draw)"; `:3` "cut on main e56d372c"; `:43` "a green strip remains on the right"; `fore_fix.diff:61` "v_grad = vec2(0.0);" | The EP names the window; Rendering re-runs its gates and a planet 7 side-by-side on that stack in the default look | Rendering, EP |
| C-36 | the record | Orb's own words on the sizes are an acceptance, not a list: `docs/ep/vision.md:1887` has "I'm okay with recommendation on all of them". What was recommended (tiny to huge now, colossal after Alpha) is written only in the questions page. The question about tiny and huge carried no recommendation, so it has no answer on file | `docs/ep/vision.md:1887`; `docs/ep/reviews/stand-in-questions-2026-11-14.md:24-25` | The EP adds a note beside line 1887 saying what the accepted recommendation was, with its date | EP |

## Confirmed fine

- **Medium with no size named is unchanged on the stack.** Parity against main's golden passes, 9 matches and 174,798 ticks identical (`docs/world/runs/planet-sizes/parity-passes-golden-unmoved.txt`, `docs/world/runs/gw1c-world/parity-passes-golden-unmoved.txt`). Those runs play no other size, so C-01 does not touch them.
- **Medium named equals medium unnamed, by the code.** Every size branch tests the column count against medium's or mixes in a zero. The `SIZES` row for it is not proof as recorded (C-01).
- **The two stale values are fixed:** the sim's radius follows the size (Simulation's grant) and the meteor reads it. The literal 38,400 in `sim/world/waterrec.gd` is replaced by a value that is exactly 38,400 at medium.
- **boxkey-gw1c moves no hash.** The two tables its keys feed are only looked up, set and cleared. Its records show the golden regenerated byte-identical and parity passing (`docs/sim/runs/554430ad/boxkey/summary.txt`). It applies on main alone and on the full stack. It answers colossal; huge was already inside the old key's range.
- **store-parts changes no record and no hash.** Its diff touches only the read. The formula and the order of the sum are as before.
- **Keys that do carry the size on the stack:** the planet memo, the slice memo, the match-key hash, the planet disk key, the places key and the plan memo, and the field's disk key through its cells and stride (`sim/world/field_cache.gd:40-42`).
- **A snapshot carries the new size field:** it copies a state by its property list (`net/snapshot.gd:117`).
- **gw1c-world leaves medium alone, by reading:** the cap and the spawn reach return early for medium.
- **Every new behaviour switch in the World parks ships off** in the data: repeats 0, furrow, groove settling, flatten, flood and the tier table.
- **The shaft cap fix is real:** the relief is read from the planet's marks, with a control on file (`docs/world/runs/globe-step2/NEGATIVE-CONTROL-1-shaft-cap-reads-no-relief.txt`).
- **The two either-state edits in crater-tiers are honest pins,** each with its reason beside it. No pin in the World parks hides a regression.
- **No park changes what bystanders do.** None edits the collateral code, and the bystanders check stays in the CI list.
- **Rendering's park files match the hashes and line counts their READMEs give.**
- **The tile ground reads the size everywhere it hard-coded medium,** and at medium the new code is the old arithmetic.
- **None of the four picture parks changes the sim.** Each has a record of the reference file byte-identical, and VFX's hash check agrees with and without the feet parks (`docs/rendering/runs/f61eb8c2/feet-hash.txt`).
- **None of the four picture parks adds a dissolve, a fade, a slow wipe, a blur or anything drawn on, over or between fighters.** None reads back from the graphics card or adds a full-screen pass.
- **Marks-baked does draw slide trenches and beam grooves under the fighters,** and rows-interp changes the shader and its CPU twin the same way.
- **With rows-interp, small and medium have no standing sample over 8 units** in the final record.
- **UI's size row reads the offered sizes from World's data, starts on Medium and uses plain words.**
- **Game Design's rulings for the sizes exist** (`docs/design/planet-sizes.md`), and Encounter's arc-by-size builds the curve ruling with a control.
- **No void timing is reported as a measurement** in any park.
- **The exit line is the same words in the sprint and the tracker** (`A1-sprint.md:50`, `docs/production/milestones.md:127`), and Orb's words are quoted exactly from `docs/ep/vision.md:1804`.
- **No park names an existing franchise or says anything personal about Orb.**

## Refuted

No finding was refuted outright. These statements inside findings did not hold; the findings above use the corrected form.

| Statement | Why it does not hold | Where |
| :--- | :--- | :--- |
| "No still of either size exists" | Stills of small, medium and big were made at 19:51 to 19:53 on 2026-11-20. They are untracked and unrecorded | C-03 |
| "No frame, load or memory reading for any size, medium included" | Valid medium readings exist on older builds (for example `docs/rendering/pending/2026-11-02a-fill-floor/README.md:11`). None on the 9 November build or later | C-06 |
| "Only tiny has been played on its own ground; huge's coarser bake has never been made by a check" | `SIZES` plays huge for 5 ticks after `WorldPlanet.forget()`, so on its own ground. The 600-tick rows did share tiny's | C-11 |
| "Proven for tiny only" | Rendering's feet runs played small, medium and big for 10 seeds with the memo fix. They are not hash records | C-11 |
| "The memo keeps three per seed and size" | It keeps up to three in total (`sim/world/field.gd:167`) | C-12 |
| "No owner on file" for the lattice and the frame reading | The design page names World (`planet-a1-design.md:69`); the sprint names Performance (`A1-sprint.md:40-43`) | C-12, C-06 |
| "The same launch is framed twice as wide on big" | The factor scales the shot's limits, not the frame | C-13 |
| "No park fixes the lakes" | Two parks were written at 20:01 to 20:06 on 2026-11-20, after the reviewers read. Neither is gated | C-20 |
| "Planet-sizes' three records hold no flash line" | Two of the three show the gates' flash checks passing at medium. No measured reading exists | C-21 |
| "The crater-tiers data row makes craters three times as wide for the player" | The table is read only with the energy model off; on Orb's path the model decides. Downgraded to minor | C-32 |
| "Main could not reproduce the GW1a target in any recorded match where a fighter above level 0 lands a shot" | Not checked whether the target holds such a match. The finding stands on the rule differing from the 9 November build | C-02 |

## How this was done

- Four reviewers, one per lens: the sizes in the sim, terrain and destruction, the picture, and measurement with owners and the exit line. Each read the parks' READMEs and patches in full and reported with file, line and quote.
- Every blocker and major went to a checker whose job was to refute it. Minor findings were checked against the files by the report writer.
- The report writer also rebuilt the apply table on a fresh scratch copy of 1f5fc401, opened the size stills, and re-read the files for any checker's correction that arrived cut short.

| | Count |
| :--- | :--- |
| Findings from the reviewers | 46 (32 blocker or major, 14 minor) |
| Sent to a checker | 32 |
| Held as stated | 25 |
| Held with corrections (the core stood) | 7, one of them downgraded to minor |
| Refuted outright | 0 |
| Minors checked by the report writer | 14, all held |
| Findings after merging duplicates | 36: 6 blocker, 16 major, 14 minor |

Of the 36, C-36 and the lake-patch rows of C-07 were found by the report writer.

Checkers marked five verdicts as medium confidence: C-09 (the reverse replay case is read, not run), C-15 (read, not run), C-05 (read, not run), C-13 (the mechanism), and C-32.

One thing to disclose: during the review a mis-chained shell line ran `git commit` inside the repo after a failed step. Nothing was staged, so git made no commit. The head and the index were checked afterwards and were untouched.

Not covered: nothing was run, so every "would fail" above is a reading. The UI stack was not built, so UI's row and the `main.gd` merge were not apply-checked in place.

Cost: about 4.4M tokens (37 agents: 4 reviewers, 32 checkers, 1 writer). A first attempt earlier the same evening stopped on the weekly limit with nothing written and cost about 1.0M more.

# GW1b landing review, before the stack (2026-11-20)

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **What:** every park named for GW1b, read against main at `8baf6f8a` and against the EP's GW1a tree (cut from main at `d55c612f`, its last commit "gw1a-final"). GW1a is not on main yet, so a GW1b park has to apply on the GW1a tree.
- **How:** read-only. No Godot and no browser was run. Reviewers ran `git apply --check`, `node tools/validate.js` and its self-test on scratch copies only. Nothing in the repo or in the GW1a tree was changed.
- **Words used once:** a *park* is finished work waiting in `docs/<area>/pending/`. A *rider* is a small rule change that rides GW1b's re-record. The *golden* is the recorded reference matches. A *lane* is one run of the golden with a rider in and one with it out. A *pin* is a change to a check so it passes on the new tree. A *grant* is a patch into another director's file. The *flip* is the one data line that makes the round planet the default world.

## Verdict

**Stack after the named fixes; do not stack the list as it stands.** Three listed patches do not apply on the GW1a tree (the flip itself, the energy data grant, World's menu grant), one park is not GW1b's and would switch on the lodge hold that Orb asked to play first, and three visible changes have no picture in the default look. The order below lands the world's code switched off first, then the riders, and the flip last as its own commit, so every step can be checked against a record that exists.

## Proposed stack order

The reviewers disagreed on one point. Two said "A-WORLD-01 first, as the sprint plan says" (`docs/ep/sprints/A1-sprint.md:22` "it is the first step of GW1b"). Two said "the flip last". Both can be true: A-WORLD-01's **code** goes first and changes nothing while the mode is `arena`; the **data flip** goes last. The reason: the flip moves every reference match that names no planet (B-02), and every rider's record was taken on the hand-made arena. With the flip last, each rider's moved rows can be read against its own record, and one re-record at the end covers everything. A reviewer applied the whole stack in both orders and got the same files, so the order is a choice about proof, not about conflicts. The EP's line in the sprint plan says "first step"; if the EP wants the flip itself first, steps 5 to 19 need their lanes re-taken on the planet.

Before step 1: GW1a lands on main, and the GW1a tree is rebuilt with World's current `pins-gw1a.diff` (B-45).

| # | Park and patch | Applies on | Why here | Re-run or re-record after it |
| :-- | :--- | :--- | :--- | :--- |
| 1 | `world/a-world-01/a-world-01.diff`, with Tools' six biomes-world cases (re-cut owed, B-10) | the GW1a tree | everything of the world step needs `WorldDefault`; the cases keep the self-test green | validate, self-test, `world_default_check`; golden must be byte-identical (mode is `arena`) |
| 2 | `world/a-world-01/grant-simulation-sim.patch` | after 1 | the one line in `beginMatch`; does nothing in arena mode | parity; golden byte-identical |
| 3 | `architecture/replay-world/replay-world.patch` | after 1 | the replay header names the default world | parity's new row; golden byte-identical |
| 4 | `world/checks-gw1a/pins-gw1b.diff`, re-cut with the full list (B-09) | after 1 | a no-op in arena mode, so it can land with the code | World's whole check list |
| 5 | `architecture/meters-zero/meters-zero.patch` (three-way, or re-cut, B-22) then `grant-narrative-meters.patch` | after 3 | gw1b-energy is cut on top of it | parity; a lane |
| 6 | `architecture/gw1b-energy`: the **re-cut** `power.json` grant (B-04), `gw1b-energy.patch`, `grant-narrative-feeds.patch` | after 5 | same table in `parity.gd`, same two `meters.json` files | `power_check`, `kick_check`, two_states with the slip on; a lane; the side-by-side of B-20 |
| 7 | `world/bystanders-gw1b/bystanders-gw1b.diff` | any time (either-state) | without it `bystanders_check` fails 2 rows after step 6 | `bystanders_check` on this tree (B-37) |
| 8 | `director/gw1b-riders/gw1b-riders.diff` | the GW1a tree, plain | same batch as 5 and 6: the swing stops reading the meters; the meteor bowl row gw1b-energy names is fixed here | director set; a lane |
| 9 | `director/index-stage/index-stage.diff` (**not on the list; needed**, B-16) | the GW1a tree, plain | wall-cone is cut on top of it | `knock_wall_check`, `walk_check` |
| 10 | `director/wall-cone/wall-cone.diff` + `grant-tools-schema.patch`, with Tools' `wall-cone-cases` | after 9 | carries the cone's one number | validate, self-test; golden unmoved (its lane is on record) |
| 11 | `director/launch-cone/launch-cone.diff` | after 10 | shares lines of `launch.gd` with wall-cone | the picture and render run of B-15; a lane |
| 12 | `director/stray-beams/stray-beams.diff` (three-way, or re-cut), its grant, `dash-probe.diff`; then Controls' `stray-beams-input` | the GW1a tree (plain apply fails on one data line; three-way is clean); any order with 8 and 13 | players' presses only | director set, input suite; a lane on the GW1a data (B-17) |
| 13 | `director/beam-aim-throw/beam-aim-throw.diff` | plain | its README names `dropOnPress` as a case it covers | `aim_throw_check`; a lane |
| 14 | Tools' CI lines for the three new director checks (owed, B-23) | with 11 to 13 | the check-script count sits exactly on its limit | `node tools/check-scripts-table.mjs --check` |
| 15 | `director/floorlift-rise/floorlift-rise.diff` | plain | must be in before or with the floor grant, or Encounter's fight row fails | `floorlift_check` |
| 16 | `world/floor-rise/grant-simulation-floorfor.patch` + `floor-rise.diff` + `architecture/floor-rise-unpin/parity-lake-unpin.patch`, one commit | after 3, 5, 6 (all edit `parity.gd`) and 15 | the unpinned parity row fails without the grant | `floor_rise_check`, parity; a lane |
| 17 | `rendering/join-press/join_press.diff` | plain | shares no file with any other park | the render gates; Controls' answer (B-24) |
| 18 | `animation/step-up/step-up.patch` + `step-up-schema.patch` + `tools/step-up-cases/step-up-cases.patch`, one commit | after 16 | view only; it has a purpose only with the floor rise | `anim_check`, validate, self-test; the retaken side-by-side (B-08) |
| 19 | `camera/gw1b-scape-side/gw1b-scape-side.patch`, then `camera/gw1b-keep-human/gw1b-keep-human.patch` | scape-side first; keep-human fails alone | render only; after every sim change, because their ceilings were measured without the riders | `chase_rush_check`, `launch_shots_check`, `own_pane_check` once on the finished tree |
| 20 | `world/a-world-01/data-switches-gw1b.diff`, **re-cut** (B-01), mode only, the draw left off (B-03) | after 1 | the flip: every match with no planet moves to planet 7 | one full gate with the mode on `planet`, each owner's pins parked first (B-02, B-13); then **the one re-record** of the golden |

**Left out of GW1b:**

| Patch | Why |
| :--- | :--- |
| `world/wall-hold-split/wall-hold-data.diff` | switches the lodge hold on; its README says GW2 (B-05) |
| `world/wall-hold-split/wall-hold-split.diff` | does not apply; stands on GW1c's globe-step2 (B-06) |
| `camera/gw1b-chase-rebase/gw1b-chase-rebase.patch` | loosens a limit; the GW1a tree is already green without it (B-21) |
| `world/a-world-01/grant-rendering-main.patch` | does not apply; superseded (B-07) |

**A later data step, not GW1b:** `random.enabled` true (the quick-match draw). It needs Rendering's `world-menu-merge`, UI's `a1-world-menu` with its schema line, Rendering's `fore-clamp`, and the stills of B-03. My reading of the files, not a test: with the draw off, a menu match with no planet already gets planet 7, touch 3 from the globe ground (`render/core/tile_ground.gd:103-108` in the GW1a tree), so the two menu parks are not needed for the flip itself and B-07, B-11 and B-12 can leave GW1b's path with them.

**Pending: named by the EP for GW1b after the reviewers had read (added by the stand-in, 2026-11-20, about 20:15). Neither was reviewed in depth; what follows is from apply checks on scratch copies of the GW1a tree's files and from the READMEs.**

| Item | State | Where it would sit | What I checked |
| :--- | :--- | :--- | :--- |
| Tools' `wall-cone-cases` | parked; confirmed by the EP as GW1b | step 10, as above | On the GW1a tree's files: Encounter's schema grant, then `wall-cone-cases.patch`, then `step-up-cases.patch` all apply (the last with a line offset only); the two case patches apply in either order |
| The lake fix: World's `docs/world/pending/lake-places` (`lake-places.diff`, `lake-places-data.diff`, `grant-rendering-tile-water.patch`), Rendering's `docs/rendering/pending/water-everywhere`, and Animation's check `docs/animation/pending/water-tile-check` | parked at 20:07 to 20:13; World and Rendering still working | After step 16 (the floor rise works on the same lake floors) and **before step 20**: the flip is what puts lakes in front of every player, and the fault is fighters standing up to 681 units over an undrawn lake. The `lakeMax` data row goes with the flip's data rows | `lake-places.diff` applies on main but **fails on the GW1a tree** ("patch failed: sim/world/plan.gd:38"; GW1a's cache-determinism edits that file), so it needs a re-cut. `lake-places-data.diff` fails alone ("data/biomes/field.json:16"); it edits the key the first diff adds. Rendering's `water_everywhere.diff` and World's `grant-rendering-tile-water.patch` carry the same two changed lines of `render/core/tile_field.gd`: **apply one, never both**. Both apply on the GW1a tree, and so does Animation's check patch. It is a visible change (lakes that drew no water now draw it), so it needs a side-by-side in the default look before the flip. The GW1c review found that `marks_baked.store-parts.diff` no longer applies after it (C-07 there) |
| Camera's fight-3 feed-forward ease | **not parked yet** | With step 19: render only, after every sim change, so its limits are measured on the finished tree. It eases a camera move, so it needs its side-by-side in the default look and readings in both modes on record, as scape-side and keep-human have | nothing to check yet |

## Conflicts

Every file touched by more than one GW1b patch, or by a GW1b patch where a GW1a park changed the same lines.

| File | Patches | Hunks overlap? | What fails `git apply --check` on the GW1a tree |
| :--- | :--- | :--- | :--- |
| `data/biomes/world.json` | a-world-01.diff (creates it), data-switches-gw1b.diff | context line differs ("GW1a" against "GW1b") | the flip: "patch failed: data/biomes/world.json:1", also at -C1 (B-01) |
| `data/fight/power.json` | gw1b-energy's grant-data-gw1b.patch; GW1a's data-fight-gw1a | yes, the one `dash` line | "patch failed: data/fight/power.json:105"; no three-way base in the repo (B-04) |
| `sim/core/tools/parity.gd` | replay-world, meters-zero, gw1b-energy, parity-lake-unpin; GW1a's a1-owed/never-cut | no | meters-zero plain: "patch failed: sim/core/tools/parity.gd:5477" (applies three-way); gw1b-energy.patch before meters-zero fails at :4226 |
| both fighters' `meters.json` | grant-narrative-meters (effects), grant-narrative-feeds (sources) | no | none, in that order |
| `data/director/interrupts.json` | stray-beams.diff; GW1a's director-rows | context line (`"enabled": false` against `true`) | plain: "patch failed: data/director/interrupts.json:294"; clean three-way |
| `sim/director/beam_move.gd` | gw1b-riders, stray-beams, beam-aim-throw | no (all six orders give the same file) | none |
| `sim/director/swing.gd` | gw1b-riders, launch-cone | no | none |
| `sim/director/launch.gd` | wall-cone, then launch-cone | launch-cone is cut on wall-cone's lines | launch-cone alone: "patch failed: sim/director/launch.gd:1294" |
| `sim/director/tools/knock_wall_check.gd`, `walk_check.gd` | index-stage, then wall-cone and launch-cone; GW1a's gw1a-pins | yes | wall-cone without index-stage: "knock_wall_check.gd:10"; launch-cone: "walk_check.gd:12" |
| `render/core/main.gd` | World's grant-rendering-main.patch, Rendering's world_menu_merged.diff; GW1a's UI start-flow grant | yes | World's grant: "patch failed: render/core/main.gd:1337"; Rendering's merge applies |
| `render/camera/split_rig.gd` | gw1b-scape-side, then gw1b-keep-human | keep-human is cut on scape-side | keep-human alone fails at :280 |
| `render/camera/tests/chase_rush_check.gd` | gw1b-chase-rebase; GW1a's gw1b-chase-measure | same constants | none (left out for another reason, B-21) |
| `tools/fixtures/cases.json` | step-up-cases, wall-cone-cases, world-schema-cases; GW1a's camera-swing-cases | all append at the file's end | world-schema-cases: "patch failed: tools/fixtures/cases.json:313987"; the other two apply in either order |
| `tools/world-checks.json` | a-world-01.diff, floor-rise.diff | no | none |
| `data/biomes/brunt.json`, `sim/world/crater.gd`, `sim/world/tools/repeat_check.gd` | wall-hold-split.diff, wall-hold-data.diff; GW1a's pins-gw1a | yes | split: "crater.gd:199" and "repeat_check.gd:61"; data row: "brunt.json:66" |
| `docs/animation/step-up.md` | step-up.patch; an untracked copy in main's working tree | whole file | on main's working tree: "already exists in working directory" (B-44) |

## What GW1b changes

"Record" means a run record on file. Most rider records were taken on older stacks than the GW1a tree (B-17).

| Park | Hashed state? Record | Seen or heard? Side-by-side on record | New or changed data keys; schema |
| :--- | :--- | :--- | :--- |
| a-world-01 code, sim grant | no while the mode is `arena` (World's parity run, on another stack) | no | new file `data/biomes/world.json`; `biomes-world.schema.json` and its `map.json` entry in the same diff; **no cases** (B-10) |
| a-world-01 flip | **yes**, every match with no planet; **no golden or parity run in planet mode on file** | yes; "Look gate: Not run" (README:22) | `mode` planet; `random.enabled` (leave false) |
| replay-world | golden unmoved in arena mode (`docs/sim/runs/8ad6286a/replay-world`); the replay header and data hash change in planet mode | no | none |
| pins-gw1b | no (checks only) | no | none |
| meters-zero | yes (`docs/sim/runs/8007de44/meters-zero`, on 8007de44) | no in the default look | `meters.json` effects; schema already allows them |
| gw1b-energy | yes (`docs/sim/runs/33f30f2f/gw1b-energy`, slip off, no GW1a data) | **yes** (flight 5,000 to 3,500, a sent body 2.0 to 1.5); **none on record** (B-20) | `power.json` values; `meters.json` sources; no shape change |
| gw1b-riders | yes for the meteor bowl and the computer's beam hold; check-level record only on the 9 November data | yes (bowl 4,571 to 6,046); none named | `swing.json` `direction.anguish` 2 to 0; no shape change |
| index-stage | no (checks only) | no | none |
| wall-cone | no; a lane is on record (`docs/director/runs/4327cfbb/wall-cone/gacone/log.txt:51` "SAME lines with and without the rider") | no | `launch.json` `wallCone`, `wallBy`; Tools' grant, approved, cases parked |
| launch-cone | yes; a lane (1 of 11 rows on each data set) | **yes** (about half the building smashes go); **none** (B-15) | none of its own; reads `wallCone` (B-31) |
| stray-beams | by reading: only matches with a person's input; no record on the GW1a data | no (a quiet refusal) | `interrupts.json` `ownMove.dropOnPress`; a grant with no Tools review and no cases (B-24, B-30) |
| beam-aim-throw | by reading: yes, the computer's beams included; no record on the GW1a data | a beam that fired wide now goes at the rival; none | none |
| bystanders-gw1b | no (one check file) | no | none |
| floor-rise, floorlift-rise, floor-rise-unpin | yes wherever the floor is on and a fighter's own step climbs it (World's and Simulation's READMEs) | yes (a lift of up to 144 units in one tick); only through step-up's picture (B-08, B-14) | none |
| join-press | no recorded match moves | no | none |
| step-up, step-up-cases | no | yes; a side-by-side exists but **not in the default look** (B-08) | `ground_motion.json` `step_up`; schema grant approved by Tools; 13 cases |
| gw1b-scape-side, gw1b-keep-human | no | yes; side-by-side in the default look and readings in both modes (`docs/camera/runs/d55c612f/window/`, commit 7719a9e0) | camera params only |
| gw1b-chase-rebase | no | no | none (left out) |
| wall-hold-split | split: state hash no, replay data hash yes; data row: yes | data row: yes; none | `brunt.json` `repeatCraters`; schema in the same diff (left out) |

## BLOCKER

**B-01. The flip does not apply.** Park: `docs/world/pending/a-world-01` (`data-switches-gw1b.diff`).
- Wrong: its context line is an older wording of the file its own park creates.
- Evidence: `a-world-01.diff:252` creates "shipped until the golden window GW1b"; `data-switches-gw1b.diff:6` expects "shipped until the golden window GW1a". On a scratch copy: "error: patch failed: data/biomes/world.json:1". Git log: `ee2cf459` reworded the first after `a9b38128` cut the second.
- Fix: re-cut against the file `a-world-01.diff` creates, and state the apply check in the README. Owner: World.

**B-02. The flip moves the golden for every match with no planet, and only World's checks are ready for it.** Parks: `a-world-01` (the flip with `grant-simulation-sim.patch`), `replay-world`.
- Wrong: the hook sends every headless match with no planet to planet 7, touch 3, generation 3. That is every default recipe of the golden and most check scripts of every director. No golden, full parity or other director's gate run with the mode on `planet` is on file. Neither README says the golden moves at the flip or who re-records it.
- Evidence: `grant-simulation-sim.patch:7` "setup = WorldDefault.apply(setup, seed, true)". The GW1a tree's `sim/core/tools/golden_recipes.gd:31, 69, 185, 210, 252, 344, 437, 446, 530` start matches with no planet key. `a-world-01/README.md:3` "With the shipped data this changes nothing". World's own flipped run: "44 pass unchanged, 41 fail, 2 gave no verdict" (`docs/world/runs/a-world-01/flipped-data-checks.md`). Files outside World that start matches through the sim, in the GW1a tree: sim/director 66, sim/input 26, sim/core 23, qa/godot 22, audio/tools 16, render/camera 14, net/tools 10, render/tools 5.
- Fix: stack the flip last (step 20). Before it, one full gate on a scratch stack with the mode on `planet`; each owner parks pins or re-reads for its red rows (rows that are about the arena take `world: "arena"`). Simulation's README names the one re-record and adds the recipe `docs/ep/reviews/path-round-2.md:57` asked for ("at least one recipe on planet 7 at generation 3 with a crater and a slide"). World's README says the flip moves the golden.
- Owner: World (park, README), Simulation (re-record, parity), EP (routing each director's pins).

**B-03. The flip also turns on the quick-match draw, which is not ready to be seen.** Park: `a-world-01` (`data-switches-gw1b.diff`, `random.enabled`), with `docs/rendering/pending/world-menu-merge`. The checker corrected the first statement; this is the corrected one.
- Wrong: from a player's second menu Start, a match would play one of 15 worlds (planets 7, 12, 3, 13, 17 at touch 1, 2 or 3). The 9 November build showed planet 7 at touch 3 only. Rendering did take stills of all five planets, at touch 3, on an older stack. They showed two faults (teeth on planet 12's beach, planet 17's river as two bands). Rendering's fix, `docs/rendering/pending/fore-clamp`, is not in the GW1a tree and not on the GW1b list, and by its own README planet 17's band is "half gone". Touches 1 and 2 have no picture. Planet 12 read FAIL on the flash analyser in both modes on that (non-standard) clip, before and after the fix.
- Evidence: `data-switches-gw1b.diff:11` '"random": { "enabled": true'. `a-world-01/README.md:22` "5. Look gate | Not run". `docs/rendering/runs/4f06e7a3/planets-globe-stills.txt:1` "7 (the reference), 12, 3, 13 and 17", and its lines on planet 12 ("a row of dark spikes") and 17 ("two bands of water"). `docs/rendering/pending/fore-clamp/README.md` table: "planet 12, reduced | FAIL 4.5 / 4.5 / 2.5 | FAIL 3.5 / 3.5 / 2.5". `world-menu-merge/README.md:29` still says "only been looked at on planet 7" (stale).
- Fix: flip the mode alone in GW1b; `random.enabled` stays false, so every match is planet 7, touch 3, as on 9 November. Turn the draw on as its own data step with fore-clamp, stills of the other four planets and of touches 1 and 2 on the GW1b tree with Reduce flashing on, Camera's and VFX's word on whether the safety readings hold off planet 7, and the EP's look.
- Owner: World (data row), Rendering (fore-clamp, stills).

**B-04. The energy data grant does not apply, and a hand merge would switch the slip's brake off again.** Park: `docs/architecture/pending/gw1b-energy` (`grant-data-gw1b.patch`).
- Wrong: the patch rewrites the whole one-line `dash` object and carries the slip off on both sides. GW1a turned the slip on in that line. The patch's base file is not in the repo, so there is no three-way merge. The park's proof was taken with the slip off.
- Evidence: `grant-data-gw1b.patch:17` and `:19` both read '"slip": {"enabled": false'. The GW1a tree's `data/fight/power.json:113` '"slip": {"enabled": true' and `:115` "On since GW1a (sprint A1): the 9 November build Orb played had it on". Apply: "error: patch failed: data/fight/power.json:105". README:39 "Cut on 33f30f2f with the stack above".
- Fix: re-cut on the GW1a tree so only `flight.flatOut`, `launchTravel`, `dash.closeSec` and their notes change; re-run `power_check`, `kick_check` and two_states with the slip on and replace the README's numbers. The EP must not hand-apply the `dash` line. Owner: Simulation.

**B-05. The wall-hold data row switches on the lodge hold.** Park: `docs/world/pending/wall-hold-split` (`wall-hold-data.diff`).
- Wrong: it flips all five numbers at once, the lodge value among them. The park's split is a different one from the split `path-round-2.md` asked for: it splits the crater repeat out of `repeatMarks`, not the lodge out of the row. Its own README places the row in GW2. The wall values cannot simply go on without the lodge value: one function reads one key for both.
- Evidence: `wall-hold-data.diff:11-14` '+  "wallRebound": 0.0,' ... '+  "lodgeHold": "body",'. README:8 "This is the GW2 data row". `docs/ep/vision.md:1862`: "[x] Wait until I play it - Notes: I want fights to be fast paced..." and `:1355` "wait until Orb plays it". The GW1a tree's `sim/world/brunt.gd:1143-1149`: 'if str(cfg().lodgeHold) == "body":' and only under it 'if int(cfg().wallDepthHold) > 0:'.
- Fix: keep both wall-hold data diffs (this one and `wall-hold-on/wall-hold-data.diff`, which does apply) out of GW1b. World re-cuts a wall-only key, which needs a code change in `_hold`; Tools cuts Orb a private build with the full row; the lodge value goes on only on Orb's word. Owner: World.

**B-06. The wall-hold key split is not a GW1b park and does not apply.** Park: `docs/world/pending/wall-hold-split` (`wall-hold-split.diff`).
- Wrong: it stands on globe-step2 (GW1c) and on wall-hold-on's pins, and neither is in the GW1a tree; both also fail to apply there. Its README never says GW1b. The diff has no index lines, so no three-way fallback.
- Evidence: "error: patch failed: sim/world/crater.gd:199" and "sim/world/tools/repeat_check.gd:61". README:7 "Stands after globe-step2 and after `wall-hold-on/wall-hold-pins.diff`". `docs/ep/sprints/A1-sprint.md:50` puts "the step 2 re-cut landed" in GW1c's exit line.
- Fix: take it out of the GW1b stack. World re-cuts it on the GW1a tree or for GW1c, and the README says which window. Owner: World.

**B-07. World's grant to `render/core/main.gd` does not apply, and its replacement is not on the list.** Park: `a-world-01` (`grant-rendering-main.patch`). One checker read this as a blocker, another as a major; the listed patch rejects, so it is listed here, but the fix is a change to the list.
- Evidence: "error: patch failed: render/core/main.gd:1337" (the GW1a tree's `main.gd:1392` has UI's `_slots` line inside its context). `world-menu-merge/README.md:9` "World's patch as filed doesn't apply on the stack". `world_menu_merged.diff:18` calls `ui_hud.first_match_played()`, which only `docs/ui/pending/a1-world-menu/world-menu.patch:226` adds. `a-world-01/README.md:9` and `:36` still name the old patch.
- Fix: drop the grant and mark it superseded in World's README. `world-menu-merge` and `a1-world-menu` land together, with the draw (see B-03), after B-11 and B-12 are fixed. Owner: World (README); Rendering, UI, Tools (the replacement).

**B-08. The only picture of the floor lift was not taken in the default look.** Park: `docs/animation/pending/step-up` (it covers World's floor-rise).
- Wrong: the side-by-side was made on the old strip ground with the `notiles` word, which the shipped game does not use, and the lift was staged by hand. The change ships switched on. Game Design's ruling leans on this view ("Nothing is ever drawn inside the bank", `docs/design/buildings.md:329`), so the claim is shown only on a ground the player never sees.
- Evidence: `docs/animation/runs/a25e9d9b/step-up/README.md:3` "Scratch web exports on the strip ground (`notiles`)" and `:5` "The lift is staged by hand". The GW1a tree's `render/core/main.gd:247` "RenderTileGround.on = not args.has("notiles") and not strip_ground   # the globe ground: on". `step-up.patch:204` '"step_up": {"enabled": true'. The pictures are git-ignored (`.gitignore:65-68`).
- Fix: retake on the default build: globe ground, Reduce flashing on, both fighters, same ticks; use the lift Encounter's check found (B-27) if it can be reached; say so in the run README. The EP looks before stacking steps 16 and 18. Owner: Animation (Tools' launcher).

## MAJOR

**B-09. World's list of arena pins for the flip is incomplete.** Park: `docs/world/pending/checks-gw1a` (`pins-gw1b.diff`).
- Wrong: checks pinned only for GW1a's data also start matches with no planet and assert the hand-made world. `WorldPin.shipped()` does not set the world mode, so those rows play planet 7 after the flip. The 12 pins that exist are honest by reading; 11 have no run record and one was never run.
- Evidence: `farsites_check.gd:115-117` 'newMatch(Sh, 1, {}, {"intro": false})' then "the hand-made world has none"; `arena_check.gd:145` "# no planet: the hand-made world is 4,800"; also `sea_rules_check.gd:15-17`, `street_axis_check.gd:167-169`, `ground_check.gd:152`. Failing rows, GW1a data against the flipped run: CRATERS 0 to 14, FILL 2 to 9, FLOOR 3 to 8, GROUND 5 to 11. `checks-gw1a/README.md:34` "pinned for the mode by static reading, not run".
- Fix: run the whole World list on the GW1a tree with a-world-01, both pin diffs and the mode on `planet`; add the pin or `world: "arena"` where needed; file the verdict lines; run `depthreads_check` in a quiet window; reword `planet_world_check`'s row "a setup without a planet is today's world". Owner: World.

**B-10. The new world schema lands with no invalid cases, so CI's self-test goes red.** Parks: `a-world-01` (`a-world-01.diff`), `docs/tools/pending/world-schema-cases`.
- Evidence: on the scratch stack, "FAIL  coverage: biomes-world.schema.json: at least three invalid cases / has 0" (10,116 of 10,117; the untouched copy passes 10,110 of 10,110). Rule: `tools/lib/selftest.js:228`; CI: `.github/workflows/ci.yml:76-77`. The cases are in a park labelled "(GW1c; Tools, parked 2026-11-14)", bundled with the sizes cases, and it fails at `tools/fixtures/cases.json:313987`.
- Fix: Tools cuts the six biomes-world cases alone on the GW1a tree, to land with step 1; the six sizes cases stay with GW1c. Owner: Tools (World lists it under NEEDS FROM EP).

**B-11. UI's world-menu park changes a data file's shape with no schema change.** Park: `docs/ui/pending/a1-world-menu` (`world-menu.patch`).
- Wrong: the validator fails. The park also carries a GW1c item (the size row, inert without `sizes.json`) and puts team words on a line a player reads.
- Evidence: `world-menu.patch:336` adds '"world": "World"' to `ui/data/feedback.json`; `tools/schemas/ui-feedback.schema.json:191` closes that block. Validator on the scratch stack: 'error  ui/data/feedback.json:20 /report/world  [additionalProperties] unknown property "world"'. README:18 "Planet {planet}, generator {gen}, {cols} columns around".
- Fix: Tools' schema line and cases in the same landing; the report line in plain words; the README says the size row lands inert. Owner: UI (Tools for the grant).

**B-12. After the menu merge, the page word `planet=N` no longer wins for a match started from the menu.** Parks: `world-menu-merge`, `a-world-01` (README).
- Wrong: in planet mode the menu's planet part is never empty, and the set-up reads it before the page word. A capture that starts through the menu with `?planet=12` gets planet 7 on a never-played profile and a drawn planet after that, from a clock-based seed.
- Evidence: `a-world-01/README.md:44` "`?planet=7` shortcuts still work (an explicit planet wins)". The GW1a tree's `render/core/main.gd:480-484`: 'if not _planet_next.is_empty(): return _planet_next.duplicate()' comes before 'if args.has("planet")'. `world_menu_merged.diff` adds 'out = WorldDefault.part(_menu_seed, not ui_hud.first_match_played())'.
- Fix: skip the default when the address or command line names a planet; add a row to the menu check; Tools says which capture pages start through the menu. Owner: Rendering (World corrects the README).

**B-13. The default is applied after the host's load gate has looked at the set-up.** Park: `a-world-01` (`grant-simulation-sim.patch`), against Rendering's host and strip-ground checks.
- Wrong: with the old strip ground (`--notiles`, or a tool's `strip_ground`) the host passes a set-up with no planet, its gate sees nothing to load, and the sim then adds planet 7. In the game that start is refused. In Rendering's twelve strip-ground checks a cold planet is made and checks written for the hand-made world run on it. Rendering has no pins for the flip.
- Evidence: the GW1a tree's `render/core/sim_host.gd:98` 'if SimPlanetLoad.strict and not SimPlanetLoad.mayStart(su)' with `sim/core/planet_load.gd:47-49` 'if not setup.has("planet"): return true'. `render/tools/ground_check.gd:47` 'main.strip_ground = true   # the old strip ground'.
- Fix: the host applies `WorldDefault` before its load gate; the strip-ground checks name `world: "arena"` and are re-run with the mode on `planet` before step 20. Owner: Rendering (World says so in the grant's text).

**B-14. The floor-rise parks' own READMEs are behind the ruling and carry no look line.** Parks: `docs/world/pending/floor-rise`, `docs/architecture/pending/floor-rise-unpin`. Corrected by the checker from a blocker.
- Wrong: both still pass the look call to Game Design. Game Design answered the same day: the lift stays uncapped and the view covers it. So the cap question is closed, but nothing in these two parks points at the ruling or at the picture, and that picture is B-08's.
- Evidence: `floor-rise/README.md:32` "Game Design (a look call): a bank this steep (2.7 in 1) in one dash step reads as a pop of 144 units". `docs/design/buildings.md:329` "keep the sim's one-tick lift, uncapped." (commit `a25e9d9b`).
- Fix: both READMEs point at the ruling and at step-up's retaken side-by-side; steps 16 and 18 land in the same batch. Owner: World, Simulation.

**B-15. launch-cone changes what the player sees at launches near buildings and has no picture and no render run.** Park: `docs/director/pending/launch-cone`. Corrected by the checker from a blocker.
- Wrong: a launch's turn of the world is capped at 20 degrees (the ceiling was 180) and about half the building smashes go. It has no switch of its own: it is on as soon as wall-cone's number lands. Orb's recorded words name knocking the opponent into buildings as the satisfying part, so a cut that size should be looked at before it stacks.
- Evidence: README:23 "About half the building smashes go." (37 aimed launches against 20). `launch-cone.diff` adds "cap = minf(cap, cone)". `docs/ep/vision.md:1687`: "knocking opponent into buildings was satisfying, but I was disappointed to see them bounce back to the strip like a 'ping pong ball'". The run folders under `docs/director/runs/4327cfbb/` (launch-cone, launch-cone-v2, wall-cone) hold no render, two_states or load_split line.
- Fix: one side-by-side in the default look, same seed, `wallCone` 20 against 0 on the stacked tree, on a launch beside buildings (the lane names the 9 November data's match 6 from checkpoint 130); Rendering's 15 checks and two_states with the rider in. The EP looks; if the fight reads worse it goes back to Game Design. Owner: Encounter (Camera's capture window).

**B-16. wall-cone and launch-cone need index-stage, which is in neither the GW1a tree nor the GW1b list.** Parks: `docs/director/pending/wall-cone`, `launch-cone`, `index-stage`.
- Evidence: wall-cone alone: "error: patch failed: sim/director/tools/knock_wall_check.gd:10"; launch-cone alone: "sim/director/launch.gd:1294". The GW1a tree's `knock_wall_check.gd:12` and `walk_check.gd:15` still carry "WorldPlan.everywhereOverride = 0", which index-stage removes. `index-stage/README.md:38` "For after GW1a, with gw1a-pins." In the order index-stage, wall-cone, its grant, launch-cone, all apply plain.
- Fix: the EP adds `index-stage.diff` (sha1 821afb4a) as step 9, knowing it also lifts two of GW1a's pins. Encounter makes `wall-cone/README.md:4` say index-stage is a GW1b step. Owner: Encounter (the EP adds the park).

**B-17. Three riders are live once GW1a is main, and none has a lane on that data; the five have never run together.** Parks: `stray-beams`, `beam-aim-throw`, `gw1b-riders`.
- Wrong: stray-beams and beam-aim-throw were gated only on main `def3445a`, where the switches they depend on are off in data. Their headline "the golden doesn't move" is true there and stale on the GW1a tree. (Correction: their own new checks do turn the switches on in memory, so the changed paths are exercised by checks; what is missing is the gate and a golden lane on the GW1a data.) gw1b-riders says its changes move play with the 9 November switches, but its only parity record is on main's data. `stray-beams.diff` also rejects on a plain apply (see Conflicts); it applies three-way.
- Evidence: `stray-beams/README.md:3` "Off on main's data today, so the golden doesn't move". The GW1a tree: `data/director/interrupts.json:294` ownMove '"enabled": true'; `data/input/timing.json:57-58` '"bNoBeam": true, "bNoBeamKeepRt": true'. `sim/core/hash.gd:212` hashes every per-fighter integer. `docs/director/runs/1c19d81d/gw1b-riders/rd/parity_diff.txt` is empty (main's data). Lanes on record: launch-cone and wall-cone only.
- Fix: on the stack, before the re-record: the director set, the input suite, two_states, load_split and the render 15 once with all five in; one lane per rider. Encounter re-cuts `stray-beams.diff` and rewrites the three READMEs' golden lines. Owner: Encounter.

**B-18. wall-cone weakens `knock_wall_check`'s main row.** Park: `docs/director/pending/wall-cone`.
- Wrong: the "on, in reach" row now passes when the knock aims at no wall at all, and still prints "aimed true". The checker found it wider: the follow-up row "the wall takes him" is now guarded by a value the sim has already cleared when the flight ends, so it prints on neither data set.
- Evidence: `wall-cone.diff:184-185` removes 'aimed = want >= 0 and int(D.aimB) == want' and adds 'aimed = int(D.aimB) == want'; `:194-195` changes 'if bool(row[4]):' to 'if bool(row[4]) and int(D.aimB) >= 0:'. README:33 "the knock aims at none", while `docs/director/runs/4327cfbb/wall-cone/gacone/main_data_knock_wall_check.txt` reads "ok    on, in reach: aimed true". Neither that file nor `gw1a_data_knock_wall_check.txt` has a "the wall takes him" line.
- Fix: keep `want >= 0`; stage the row where a wall is inside the cone; read the aim before the flight clears it; if no such spot exists the check fails or prints a counted SKIPPED, never "aimed true". Owner: Encounter.

**B-19. Neither cone park closes Orb's bounce bug as written, and wall-cone's opening line contradicts its own finding.** Parks: `wall-cone`, `launch-cone`.
- Wrong: wall-cone changes nothing in play (the knock's wall aim and the walk are off in the GW1a data). launch-cone stops a send at a building far off the blow's line, which is one cause; it does not touch the bounce off the building itself. No record counts bounces before and after, and none shows the knock, zip, knock chain unchanged (launches went 214 to 209 over 30 matches).
- Evidence: `wall-cone/README.md:3` "It's the background-ricochet half of Orb's ping-pong bug." against `:57` "the background ricochets Orb saw weren't knocks aimed at walls". The GW1a tree's `data/director/launch.json:94-95` wall '"enabled": false'. `docs/ep/vision.md:1881`: "the behavior where a fighter bounces off something in the background and then ricochets in an unrealistic and immersion-breaking trajectory is something I want squashed as we head to A1".
- Fix: Encounter rewords line 3. The EP does not mark the bug closed on GW1b: QA counts, on the 9 November data with `wallCone` 20 against 0, launches that hit a building and come back to the lane, and in-air chain links. Owner: Encounter (QA for the count).

**B-20. gw1b-energy's look gate, set by Game Design's own page, has no record.** Park: `docs/architecture/pending/gw1b-energy`. Corrected by the checker.
- Wrong: flat-out flight drops from 5,000 to 3,500 and a sent body travels 1.5 times instead of 2.0, both against the GW1a tree. Game Design names a side-by-side before the EP commits; none is on file and the README has no look line. (Correction: the reason given for 1.5 does have support: the shortcut for the 9 November build opens it with `travel=1.5`, and QA's reading on that build says "travel 1.5". What is not shown is the value in Orb's own match file.)
- Evidence: `docs/design/flight-3500.md:31-33` "Rendering and VFX run the side-by-side ... on the trail and the dash at 3,500 against the 9 November build, before the EP commits (ADR 0010)" and `:22` "Read from Orb's 9 November match first." `gw1b-energy/README.md:10` "Orb's 9 November match ran `?travel=1.5`". `docs/ep/vision.md:1685` names "flat-out 3500" for that match and no travel value.
- Fix: Rendering and VFX make that side-by-side in the default look, plus a launch at 1.5; the README gains a look line; Simulation or the EP reads the travel value from the match file and writes it down. Owner: Simulation (README), Rendering and VFX through the EP.

**B-21. gw1b-chase-rebase loosens a limit; it is not a re-base.** Park: `docs/camera/pending/gw1b-chase-rebase`. Corrected by the checker from a blocker: it blocks this one park, not GW1b.
- Wrong: the step limit for an ordinary send at top power goes from 0.25 to 0.30 and the three rows that sat on ceilings are deleted, so they may rise unseen. Camera's park one step earlier calls the same rows a real sweep with a fix owed. The decision it leans on is not written in `docs/ep` or `docs/decisions`. "Orb's taste" in the check's comment is not in Orb's recorded words, which point the other way, and the same comment can be read as calling Orb "he".
- Evidence: `gw1b-chase-rebase.patch:9-10` "-const STEP_TOP: float = 0.25" / "+const STEP_TOP: float = 0.30 ... (Orb's taste: he stays at his anchor)". README:11 "the change only loosens a limit main's rows already pass". `gw1b-chase-measure/README.md:20` "Real, and the next fix". `docs/ep/vision.md:493`: "It jolted left and right in some cases, such as when a player was knocked away. A pass on the camera."
- Fix: leave it out. If the EP's decision stands, write it in `docs/ep` with its date, keep the three ceilings, and take "Orb's taste" out unless Orb is asked with a clip. Owner: Camera.

**B-22. meters-zero's patch rejects on a plain apply.** Park: `docs/architecture/pending/meters-zero`.
- Evidence: "error: patch failed: sim/core/tools/parity.gd:5477": the hunk's last context line was changed by GW1a's `a1-owed/never-cut.patch:66-67`. It applies three-way (base blob b94bfe4 is in the repo). README:32 names "HEAD 8007de44" as its base. `gw1b-energy.patch` fails without it.
- Fix: the EP applies it three-way and records that, or Simulation refreshes it on the GW1a tree and restates gw1b-energy's base. Owner: Simulation.

**B-23. Three new director checks land unwired and trip the check-script limit that CI runs.** Parks: `stray-beams`, `beam-aim-throw`, `launch-cone`.
- Evidence: on the GW1a tree, "check scripts: 267 in all; 191 in CI, 20 in the gate only, 1 not run on purpose, 55 unreviewed (ratchet 55)". `tools/check-scripts-table.mjs:79` fails over the limit; `.github/workflows/ci.yml:121` runs it. New: `stray_beam_check.gd`, `aim_throw_check.gd`, `launch_cone_check.gd`; no workflow, gate script or Tools park names them.
- Fix: Tools parks the CI lines to land with the riders (step 14), or Encounter gives each a reason in `tools/check-scripts.json`. Owner: Encounter (checks), Tools (CI lines).

**B-24. Three other-owner answers are not on record.** Parks: `meters-zero` and `gw1b-energy` (Narrative's files), `stray-beams` (Tools' schema), `join-press` (Controls' function).
- Evidence: `DIRECTORS.md:347` gives `data/fighters/` to Narrative; both `grant-narrative-*.patch` files touch the two `meters.json`; nothing under `docs/narrative` names them. Nothing under `docs/tools` names `dropOnPress` (Tools did file "APPROVE" for wall-cone's and step-up's grants). `join-press/README.md:18` "`_claim_release` is Controls' function ... Their call"; nothing under `docs/controls` answers.
- Fix: the EP routes each and records the answer in the owner's README before stacking. Owner: Simulation, Encounter, Rendering (parks); Narrative, Tools, Controls (answers).

## MINOR

Each was checked against the files by the report writer.

| # | Park | What is wrong | Evidence | Fix | Owner |
| :-- | :--- | :--- | :--- | :--- | :--- |
| B-25 | launch-cone | It puts back, for `walk_check`, the world pin index-stage had just lifted, and forces the swing off: a set-up the game does not ship. On the shipped set-up the walk reaches 0 of 10. The park says so openly, Game Design confirmed the reading, and the walk is off in data. (Corrected from major: the check never compared leaning with the switch off.) | `launch-cone.diff`, walk_check hunk: "+	WorldPlan.everywhereOverride = 0", "+	DirSwing.setForce(0)"; `lcga2/walk_check.txt` "leaning 7, switch off 7, no lean 7" | name the debt (the street turn) in the check and README; print the shipped-set-up reading as a row | Encounter, Game Design |
| B-26 | wall-hold-split, wall-hold-on | `repeatMarks` 2 does nothing a player sees with the energy model on, yet a non-zero mark is hashed. The "24 of 24" is a model-off number. (Corrected from major: the README places this row in GW2, so it is not a GW1b fault.) | `docs/world/pins-and-the-model.md:19-20` "0 of 24 with `repeatMarks` 2"; `sim/core/hash.gd:265-267` | `repeatMarks` stays 0 until memory-under-model is parked and lands with it | World |
| B-27 | step-up | "No real match produced one" leaves out a record of the same day: with World's grant on, Encounter's check fight lifted a free fighter 144.6 units in one tick. (Corrected: that fight re-places both bodies on a lake bed, so it is not a plain match.) Nobody has counted how often the crouch plays in a lake-bed fight, and no row runs a fighter up a steep slope with the row on. | `step-up/README.md:20`; `docs/director/runs/4327cfbb/floorlift-rise/fr/final_9nov.txt:23` "RIVAL free at 49914 (moved 53), from 2207.4 to 2352.0" | correct the sentence; count step-ups in that fight; add the slope row | Animation |
| B-28 | a-world-01, replay-world | Both READMEs name globe-step2 (GW1c) as a prerequisite that is not needed, and their proofs were run on other stacks. | `a-world-01/README.md:3` "Stacks after `globe-step2`"; `replay-world/README.md:3` and `:31` "On 8ad6286a"; both apply on the GW1a tree without it | correct the apply lines; re-run `world_default_check` and parity's new row on the GW1a tree | World, Simulation |
| B-29 | world-menu-merge | Once the draw is on, Start and Play again draw a planet but New match always goes back to planet 7, through a constant in the tile ground, not through `world.json`. | the GW1a tree's `render/core/main.gd:199` 'new_match_requested.connect(func(): start_match(fresh_seed()))'; `render/core/look.gd:547` "const TILE_PLANET: int = 7" | decide which is meant and route it through `planet_part`; can wait with the draw | Rendering |
| B-30 | stray-beams grant; companions | The `dropOnPress` schema grant has no cases. Tools' `wall-cone-cases` and Controls' `stray-beams-input` are not on the GW1b list. | `docs/tools/pending/wall-cone-cases/README.md:3` "APPROVE"; `docs/controls/pending/stray-beams-input/README.md:7` "After Encounter's `docs/director/pending/stray-beams/`" | Tools adds cases; the EP adds both parks straight after their riders | Tools, EP |
| B-31 | launch-cone | Its one number lives under the knock's wall block, whose switch is off, and the comment and schema text speak of knocks only. Setting it to 0 would also remove the launch cone and the cap on the launch's turn. | `launch-cone/README.md:5` "There's no data change: it reads wall-cone's one number"; `grant-tools-schema.patch:14` "Degrees around the blow's line a knock may aim at a wall" | a key of its own, or say in the comment and schema that one number governs both | Encounter, Tools |
| B-32 | launch-cone | `launch_cone_check` passes with nothing measured, and ships no `.uid` file, unlike the two beam checks. | `lcgm2/launch_cone_check.txt` "0 (0 aimed)"; `launch-cone.diff:165-166` 'if aimed == 0: print("NOTE  no launch was aimed ...' | fail or print a counted SKIPPED under a floor of aimed launches; raise the default match count | Encounter |
| B-33 | gw1b-riders | The meteor's bowl keeps its tier because its landing speed is authored; the brawl's spike crater is dug the same way and still loses its tier under the model. The README's "already inert on today's roster" holds for the base form only. | the GW1a tree's `sim/director/brawl.gd:2006`; `data/fighters/PROTAGONIST/forms.json:46` '"care": 0.5' | Encounter and World rule on the spike; correct the sentence | Encounter |
| B-34 | stray-beams-input | The README calls Orb "he". It also records that from a pad the last signature tick is 11, not 12 as Encounter's table reads. | README: "If Orb mashes after a release, he will see "Replaced" where he saw a late beam."; `:21` "11 is the last signature tick" | "they"; one line in the stray-beams README on the pad's window | Controls, Encounter |
| B-35 | wall_hold_check (GW1a tree) | It never tests the wall hold as the game ships it: the four keys are forced in memory, all off or all on, and the first row asserts today's off row, so it fails as soon as a data row lands. | `wall_hold_check.gd:17-22` 'c.lodgeHold = "body" if on else "world"'; `:131` "the data's defaults are today's behaviour" | with the re-cut of B-05: a pass that reads the data as shipped, and a row for the wall values with the lodge as today | World |
| B-36 | bystanders-gw1b | It re-reads the one failing row and leaves other feed rows passing as 0 against 0 with words that are now untrue. One comment contradicts its own code. | the GW1a tree's `bystanders_check.gd:245` "feeds him", `:254`, `:281`; `bystanders-gw1b.diff:8` "his power still rises" against `:14` 'absf(Wa.fighters[1].power - 10.0) < 1.0e-9' | either-state wording, or the old feeds put back in memory for those rows as `cross_check` does | World |
| B-37 | bystanders-gw1b | Never run on the tree it is for: not with GW1a's data, not with the planet as the default. `bystanders_check` is not among the 12 pinned checks, so which world it plays after the flip is not on record. | README:3 "On that stack (HEAD with a1-owed, energy-on, gates-shipped, meters-zero and gw1b-energy applied"; `bystanders_check.gd:26` 'SimCore.newMatch(S, seed_, {}, {"intro": false})' | run it on the stacked tree and name the world; add a row on the default planet so the nobody-dies row covers what the player sees | World |
| B-38 | wall-hold-split | "Shipped data: nothing moves" is true for matches, not replays: a new key changes `brunt.json`'s hash, which is in every replay's data hash. "World's files only: no grant" is said of a diff that edits a schema. | README:12 and :7; the GW1a tree's `sim/world/brunt.gd:149-152`, `sim/core/replay.gd:274` | say so when it is re-cut | World |
| B-39 | gw1b-energy | The re-pinned `power_check` rows compare the sim with whatever `power.json` says, so no check fails if the data is not 3,500 and 1.5. The slip's "off" row is also weaker. | `gw1b-energy.patch:95` 'near(WorldSlide.launchTravel(1.0, 0.0), SimPower.launchTravel, 1.0e-6)'; `:141` "(it was twice the slip's speed, written for flat out 5,000)" | one row that states the shipped values | Simulation |
| B-40 | meters-zero, gw1b-energy | Read together the READMEs are stale: meters-zero says the world still feeds the meters; gw1b-energy sets every feed to 0. The greybox HUD still has MENACE and ANGUISH bars that will stay empty. | `meters-zero/README.md:25` "The world still feeds the meters"; `gw1b-energy/README.md:12` "every feed to the meters is 0"; the GW1a tree's `render/core/hud.gd:230`, `:233` | correct the list; the EP routes one line to Rendering | Simulation |
| B-41 | gw1b-keep-human | The headline number is the non-default mode. In the default look the player's loss in the signature scene goes 26 to 8, a different stretch the record does not show before the change. Also open: the push favours the person, and no line prints the computer's fighter during ticks 125 to 150, where the change acts. | README:19 "26 → 0 ticks (normal); reduced reads 8"; `docs/camera/runs/5cef4af7/gw1b/runs.txt:10`; `docs/ep/vision.md:1320` "Losing track of the opponent is disruptive." | default look first in the README; print ticks 1 to 8 with keep_human off; one line on the computer's fighter | Camera |
| B-42 | gw1b-scape-side, gw1b-keep-human | Both READMEs still say the look gate is owed; it was run and committed on 2026-11-20. The pictures are git-ignored and not pointed at. Two check comments point owed fixes at pending folders that go away at landing. | `gw1b-scape-side/README.md:24` "## Owed before landing"; commit `7719a9e0`; `.gitignore:58` | update both READMEs; move the owed-fix notes to a file that stays | Camera |
| B-43 | join-press | No committed check goes through the host's hand-over; the probe was a scratch script and the render gates were not run. | README:22 "The render gates and ground checks weren't run for this one line"; `docs/rendering/runs/3070ef10/join-press.txt:1` "the probe tg/join_probe.gd (scratch)" | one committed row for a mid-match join; the render gates with the GW1b batch | Rendering, Controls |
| B-44 | step-up, step-up-cases | Three patches from two folders must land in one commit and only prose ties them. `step-up.patch` also creates `docs/animation/step-up.md`, which already sits untracked in main's working tree. | `step-up/README.md:10` "`validate` fails without it"; `git status`: "?? docs/animation/step-up.md" | apply the three back to back; remove or stage the untracked file first | Animation, EP |
| B-45 | the GW1a tree | It was built three minutes before World's last re-cut of `pins-gw1a.diff`, so it does not hold the current pins. | tree's last commit 2026-11-20 17:33:09; `554430ad` at 17:36:01; the current diff does not reverse-apply ("patch failed: sim/world/tools/wrecks_check.gd:136") | rebuild the tree before the GW1b gate | EP |

## Confirmed fine

- **Applies.** With the fixes and substitutes above, the whole stack applies on a scratch copy of the GW1a tree with no conflict markers, in both orders (world step first or last), and gives the same files. Every patch's sha1 matches its README where one is given.
- **The world code is inert until the flip.** With the mode `arena`, `WorldDefault.apply` returns the set-up it was given. A-WORLD-01's code needs none of globe-step2, planet-sizes or store-parts.
- **The draw stays out of the sim.** It is keyed on the match seed, the sim's hook always asks for the fixed planet, and a drawn planet is written into the set-up, so it is in the replay.
- **Old replays are refused, never played on the wrong world.** LAN is unchanged: its three fixed set-ups name planet 7, touch 3 and an explicit planet wins.
- **The 12 pins in `pins-gw1b.diff`** move no expected value and weaken no assertion, and do nothing in arena mode.
- **Determinism.** No clock, unseeded draw or 32-bit float is added to the sim by any park. The floor-rise grant is a pure function of the state. No render park writes sim state.
- **The two-fighter count does not rise** (365 against a baseline of 365 in every record).
- **meters-zero and gw1b-energy follow Game Design's ruling and addendum**, and do not collide. meters-zero's new parity row has a negative control on record.
- **gw1b-riders' two check hunks are honest:** they take off GW1a's ceilings and put the full rows back, with records on both data sets.
- **Orb's rules.** Nothing moves, aims or holds a player's fighter. No civilian death is added. Nothing is drawn on, over or between fighters. No dissolve, fade, slow wipe or full-screen blur. No franchise names. The lodge hold stays off as long as neither wall-hold data diff is stacked. The knock, zip, knock chain (`docs/ep/vision.md:1881`) is not touched by the energy, meter, wall or bystander parks.
- **Camera.** scape-side is a real fix, not a pin, with a side-by-side in the default look and readings in both modes. keep-human acts only in the one shared view and only when exactly one fighter is a person. gw1b-chase-measure (already in the GW1a tree) loosens nothing.
- **Placement.** floor-rise ("GW1b-bound"), floorlift-rise ("GW1b, with the GW1b riders"), floor-rise-unpin ("GW1b"), step-up ("parked for GW1b") and step-up-cases ("GW1b") each place themselves in GW1b. bystanders-gw1b says "Land with GW1b". wall-hold-split does not.
- **Main has not moved** under any GW1b-touched file since the GW1a tree was cut.

## Refuted

No finding was thrown out whole. These claims inside findings did not survive their checker.

| Claim | Why it fell |
| :--- | :--- |
| The tile ground has been looked at on planet 7 only (B-03) | Rendering took stills of all five planets: `docs/rendering/runs/4f06e7a3/planets-globe-stills.txt`. The README line is stale. |
| Game Design has not answered the floor-rise look call (B-14) | It did, the same day: `docs/design/buildings.md:329`, commit `a25e9d9b`. |
| launch-cone with no picture is a blocker (B-15) | A major: it is a rule change with a visible effect, switched by one data number, and the missing lane is the gap. |
| Only launch-cone has a golden lane (B-17) | wall-cone has one too. |
| The stray-beam parks never ran with their switches on (B-17) | Their own checks turn the switches on in memory (`stray-beams.diff:274-276`). The gate and the golden on the GW1a data are what is missing. |
| launch-cone's `walk_check` no longer tells the walk from no walk (B-25) | It never did: its rows were always "70% reach" and "no lean". |
| `repeatMarks` 2 is a GW1b change (B-26) | The park's README puts that row in GW2. |
| The reason for travel 1.5 has no record (B-20) | The 9 November build's shortcut and QA's reading both say 1.5. Only Orb's match file value is unread. |
| Encounter's record names a real match that lifted a fighter (B-27) | It is the check's fight, which re-places both bodies on a lake bed (`floorlift_check.gd:240`). |
| gw1b-chase-rebase blocks GW1b (B-21) | It blocks only itself; the GW1a tree passes without it. |

## How this was done

- Five reviewers, one lens each: the world default; the director's riders; energy, meters, walls and bystanders; the look; order and conflicts. Each read every README and patch of its parks in full.
- Every blocker and major went to a checker whose job was to refute it: 35 findings checked, 28 held, 7 corrected in part, 0 refuted whole. Three findings moved from blocker to major, three from major to minor.
- The reviewers also filed 20 minor findings. The report writer checked each against the files; all 20 hold, two with a narrowed claim (B-36, B-40).
- After merging duplicates across lenses: **45 findings**, 8 blockers, 16 majors, 21 minors.
- `docs/ep/reviews/GW1a-standin.md` does not exist; `GW1a-review.md` was read.
- **Not verified, because nothing was run in Godot:** whether `stray_beam_check` and `aim_throw_check` pass on the GW1a data or on the round planet; whether the riders' "9 November data" equals the GW1a tree's data; that stray-beams leaves computer-against-computer rows unmoved. One checker had medium confidence (B-27). Two checkers did not re-run the validator and reasoned from the schema (B-07, B-11). Camera's `differences.txt` shows a few frames over 1% different outside the ticks where the camera digest differs; the record does not say why.
- Cost: about 4.6M tokens (41 agents: 5 reviewers, 35 checkers, 1 writer).

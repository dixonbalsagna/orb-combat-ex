# GW1b re-check, after the fixes (2026-11-21)

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **When:** 2026-11-21, the day after the first review (`docs/ep/reviews/GW1b-review.md`, 2026-11-20).
- **What:** GW1b as it is parked on main now. GW1b is the round planet as main's default world (the *flip*, one data line, last) plus small rule changes (*riders*). The list builder tested main at `dce749fc`. The independent checker made its own export at `5bf9ff46`. Main is now at `575bf093`. Between `dce749fc` and `575bf093` only Tools' desktop-build workflow and Tools' own park folders changed (`git diff --stat dce749fc HEAD`: 12 files). None of those files is on the GW1b list, so the base difference does not change the result.
- **How:** read-only. Patches were applied on clean exports of the repo (`git archive`), never on the repo. Nothing was run in Godot or in a browser. Node checks ran on the exports only. Three readers checked the earlier findings. A builder made the apply list and a separate checker re-applied it. The readers ran on the cheaper model; the stand-in still has to check what they found.
- **Words used once:** a *park* is finished work waiting in `docs/<area>/pending/`. A *grant* is a patch into another director's file. The *golden* is the recorded set of reference matches. A *lane* is one run of the golden with a rider in and one with it out. A *pin* changes a check so it passes on the new tree. It is honest when it re-baselines the check to the intended behaviour and shows evidence.

## Verdict

**Hold. Do not stack yet. GW1b is ready only after the named fixes below.** The 48-patch list applies cleanly, and three of the eight earlier blockers are fixed. But Simulation's golden patch does not apply on the list in any order, and most of the re-cut parks and records are not committed. On top of that, the EP has to decide in writing whether the lake parks are in GW1b, because every new proof was taken with them in.

## The earlier findings

### The blockers (B-01 to B-08)

Fixed: 3. Still open (partly fixed): 2. Moved out of GW1b: 3.

| Id | What it was | State now | Evidence | Still owed | Owner |
| :-- | :--- | :--- | :--- | :--- | :--- |
| B-01 | The flip did not apply | **Fixed** | `data-switches-gw1b.diff:4-5` changes only `"mode": "arena"` to `"planet"`. A reader applied a-world-01, the sim grant, default-gate, the host grant, pins-gw1b and the flip on an export: all clean. The checker found the flip is list line 100, the last one, and the only line that changes the mode. | Nothing | World |
| B-02 | The flip moves the golden, and only World's checks were ready | **Partly fixed** | The gw1b-golden plan now has one re-record after the flip (PLANET_MATCH planet 7, seed 29). There is a planet run on record with the flip: `golden-plan/3_second_pass_with_intro_fix.txt:19` "parity_b: exit 0". Pins are parked by World (26), Rendering (strip-arena) and Animation (gw1b-pins). | No full gate with the mode on planet from Encounter, Controls, Camera, Netcode, Audio or QA. Simulation's planet run had no riders in it. The golden is not re-recorded. **gw1b-golden.patch does not apply on the list** (see new finding NB-1). Its README still expects World's ground-repin, which World deleted (NM-3). | EP (routing), Encounter, Controls, Camera, Netcode, Audio, QA, Simulation |
| B-03 | The flip also turned on the quick-match draw | **Fixed** | After the flip, `data/biomes/world.json:6` reads `"random": { "enabled": false`. The checker confirmed it on the fully stacked export. `a-world-01/README.md:12`: "`random.enabled` stays **false**". | Nothing for GW1b | World |
| B-04 | The energy data grant did not apply, and a hand merge would switch off the slip | **Fixed** | meters-zero, its grant, grant-data-gw1b, gw1b-energy and the feeds grant apply in order. Afterwards `data/fight/power.json:113` still has `"slip": {"enabled": true`. | Its proof was taken on the s422 GW1a tree, not on `b0e20f9a`. | Simulation |
| B-05 | The wall-hold data row switched on the lodge hold | **Moved out** | `A1-sprint.md:118`: "both wall-hold data diffs and heldMul 2.0: the wall-hold window". It is not in stage 1 of the planet-stack page. The checker found `lodgeHold` still `"world"` and `heldMul` still `1.0` on the stacked export. | The wall-hold window | World |
| B-06 | The wall-hold key split was not a GW1b park and did not apply | **Moved out** | `A1-sprint.md:119`: "wall-hold-split: GW1c". | `wall-hold-split/README.md` still names no window, and the planet-stack page's stage 2 (GW1c) does not list it. World says where it lands. | World |
| B-07 | World's grant to `render/core/main.gd` did not apply | **Moved out** | `a-world-01/README.md:13` marks `grant-rendering-main.patch` "**Superseded**" by world-menu-merge, "not part of GW1b". | The file is still in the folder, while the README ends "the rest of this folder is GW1b". Delete the file or reword that line. | World |
| B-08 | The only picture of the floor lift was not in the default look | **Partly fixed** | A retake is committed (`8fb85054`): `docs/animation/runs/f3e407ec/step-up-globe/README.md:3` "the default view (globe ground, split screen)". At `:7` it shows a real 62.8-unit lift in one tick. | The Anti-hero was not captured (`:17`). Reduce flashing is not stated. The tree pictured includes the lake parks (`:3`). `step-up/README.md:16` still points at the old picture. `gw1b-pins/README.md:25` points at `runs/dbe17b79/step-up-globe/`, which does not exist. The 837-unit lake-edge lift is not pictured (NM-8). The EP looks before the floor-rise steps. | Animation (the EP looks) |

### The majors (B-09 to B-24, plus B-30 and B-31)

B-30 and B-31 were **minors** in the first review. The director reader re-graded them as majors only because its form had no minor grade. They are kept here as minors. Two readers each checked B-23 and B-24, and their answers are merged below. The other minors, B-25 to B-45, were not re-checked, except B-44: the untracked `docs/animation/step-up.md` is still in the working tree (`git status`: "?? docs/animation/step-up.md").

| Id | What it was | State now | Evidence | Still owed | Owner |
| :-- | :--- | :--- | :--- | :--- | :--- |
| B-09 | World's arena pins were incomplete | Partly fixed | The working-tree `pins-gw1b.diff` pins 26 checks. 19 are honest: each test asserts the hand-made arena in its own text. 7 are honest in form, but no one has classed their planet rows: brunt, craters, deepen, repeat, fill, wall and memory_model. | HEAD's committed copy has only 25 checks; memory_model is in the working tree only. The 7 checks need a class for each red row (NM-2). | World (classes), EP (commit) |
| B-10 | The new world schema lands with no invalid cases, so CI's self-test goes red | **Still open** | `world-schema-cases/README.md` is still "(GW1c ...)". On the stacked list the self-test gives "10140 of 10141 ... FAIL coverage: biomes-world.schema.json". Readers got 10122 of 10123 and 10135 of 10136 on other trees, with the same single failure. CI runs the self-test (`.github/workflows/ci.yml:76-77`). With world-schema-cases applied the result is 7 fails, because `sizes.json` is GW1c's. | Tools cuts the six biomes-world cases on their own, to land with a-world-01. The six sizes cases stay for GW1c. | Tools |
| B-11 | UI's world-menu changes a data file's shape with no schema | Moved out | It waits with the draw (`a-world-01/README.md:12-13`). | UI's README still files it under GW1b. `world-menu.patch:336` still has no schema grant. The EP's out-of-GW1b list should name it. | UI, Tools, EP |
| B-12 | After the menu merge, `planet=N` no longer wins | Moved out | world-menu-merge "waits with the draw". `world_menu_merged.diff` is unchanged since `e7d544ea`. | When the draw lands, the menu skips its default when the page or command line names a planet, and a menu-check row is added. | Rendering |
| B-13 | The default world was applied after the host's load gate | **Fixed** | default-gate.diff and grant-rendering-host.patch are parked and apply. `docs/rendering/runs/809e93e5/strip-arena.txt`: "12 of 12 pass" with the pin. "DEFAULTGATE: 0". | The README cites `grant-rendering-host.txt`, but the file is `.patch`. Rendering's proof was on s422. The host grant and strip_arena are on the stand-in's list (lines 35, 40) but on no owner's order page. | World, Rendering |
| B-14 | The floor-rise READMEs were behind the ruling | Partly fixed | `floor-rise/README.md:32` gives Game Design's ruling. `floor-rise-unpin/README.md:34-36` says "ruled". | `floor-rise-unpin/README.md:36` still says the picture "is being retaken", although the retake is committed (`8fb85054`). Neither README names that path. | Simulation, World, Animation |
| B-15 | launch-cone changes what players see, with no picture or render run | Partly fixed | The render run is on record: `b17gold/first_stack_log.txt:106-125` "render cue exit 0". The launch-cone lane is on record: `goldcmp_4000908.txt`. | No ADR 0010 side-by-side in the default look (wallCone 20 against 0, a launch beside buildings, same seed). The builder found none under `docs/director/runs`. | Encounter (Camera's capture window), EP |
| B-16 | wall-cone and launch-cone need index-stage, which was on no list | Partly fixed | `wall-cone/README.md:4` names index-stage as a GW1b step. index-stage is on the stand-in's apply list (line 52) and applies. | No EP or sprint file names it yet. `index-stage/README.md:9` still says it stacks on gw1a-pins, which has landed and been cleared. | EP (the list), Encounter (README) |
| B-17 | Three riders had no lane on GW1a's data; the five never ran together | Partly fixed | All six parks were stacked on `b0e20f9a`. All 47 director checks pass (`recut_stack_log.txt`). The re-cut `stray-beams.diff` applies, while HEAD's committed copy fails ("patch failed: data/director/interrupts.json:294"). | Only 2 lane records are on file (NM-5). The input suite ran with stray-beams only. The riders never ran with World's stage 1, meters-zero or gw1b-energy. None of it is committed. | Encounter, Controls, EP |
| B-18 | wall-cone weakened `knock_wall_check`'s main row | **Fixed** | `wall-cone.diff:234` "aimed = want >= 0 and aim0 == want". The row fails when no wall can be staged. `knock_9nov.txt:6` "ok    on, in reach: the wall takes him (2)". | Only the EP's commit | Encounter |
| B-19 | Neither cone park closes the bounce bug | Partly fixed | bounce-count is parked. Its records (`docs/director/runs/b0e20f9a/b19-bounce/`) show cones 20 against 0 cut the bounces from 22 to 13, and "every slam that's left still bounces: 13 of 13". This confirms the first review. | `wall-cone/README.md:3` and `launch-cone/README.md:3` still call the cones the fix. The in-air chain links are not counted. The EP must not mark the bug closed on GW1b. | Encounter, EP |
| B-20 | gw1b-energy's look gate had no record | Partly fixed | **A record exists**: `docs/rendering/runs/ed1591cb/b20-gw1b-energy.txt` (9 Nov build against GW1b steps 1 to 6, both modes). Safety numbers are not judged here. | The record is untracked. `gw1b-energy/README.md:63` still says "Not taken yet". The travel value has not been read from Orb's 9 November play file. The EP looks at the GIFs. | Rendering, Simulation, QA |
| B-21 | gw1b-chase-rebase loosens a limit | Moved out | `A1-sprint.md:121`: "held until Orb answers the camera question". | If it comes back: drop "Orb's taste" and "he" (`gw1b-chase-rebase.patch:10`, README:3) | Camera |
| B-22 | meters-zero rejected on a plain apply | **Fixed** | Re-cut on the GW1a tree. meters-zero.patch and its grant apply plain, then gw1b-energy's three patches. | Narrative's sign-off (B-24) | Simulation |
| B-23 | Three new director checks land unwired and trip the check-script limit | **Still open** | `tools/check-scripts.json:3` "unreviewedMax": 55. `docs/tools/check-scripts.md:3` "55 unreviewed". No workflow, check-scripts reason or Tools park names `stray_beam_check`, `aim_throw_check` or `launch_cone_check`. Animation's `water_tile_check.gd` is unwired too ("Not in CI"). **The readers disagree:** the director reader reports a run on an export ("58 unreviewed (ratchet 55)", fail). The builder and the other reader say the tool cannot run in an export, and `tools/check-scripts-table.mjs:23` does call `git ls-files`. So the 58 is not confirmed. | Tools parks the CI lines, or the owners give reasons. Then run `check-scripts-table --check` on the stacked tree inside a repository. | Tools; Encounter, Animation |
| B-24 | Three other-owner answers were not on record | **Still open** | No Tools review of `stray-beams/grant-tools-schema.patch` (sha1 `952f78d0`). Nothing under `docs/narrative` names meters-zero, gw1b-energy or the grants. `join-press/README.md:18` still says "Their call". | Tools' APPROVE or re-cut on dropOnPress. Narrative's yes on both meters.json grants. Controls' answer on join-press. | EP (routing); Tools, Narrative, Controls |
| B-30 (minor) | The dropOnPress grant had no cases; the companion parks were off the list | Partly fixed | wall-cone-cases and stray-beams-input are on the list straight after their riders (lines 55, 60). stray-beams-input was re-staged: 21 of 21, suite 46 of 46. | No invalid cases for `ownMove.dropOnPress`, and the virtual fixture does not have the key | Tools |
| B-31 (minor) | One cone number governs knocks and launches, but the text says knocks only | Still open | `launch-cone/README.md:5`. `wall-cone/grant-tools-schema.patch:14` "a knock may aim at a wall". | A key of its own, or a comment and schema text saying the one number governs both | Encounter, Tools |

## The apply list

- **Where:** `docs/ep/reviews/GW1b-stack.txt` (untracked, written by the builder). It has **48 patches**, one `ap` line each, and the flip is last (line 100).
- **Builder:** on two fresh exports of `dce749fc`, all 48 pass a plain `git apply --check`, then `git apply`, one at a time. On the stacked export: `validate.js` gives 0 errors. The self-test gives 10140 of 10141 (the one fail is B-10). `world-checks --verify` gives "ok, 91 checks".
- **Independent re-apply: PASS.** On its own export (`5bf9ff46`), the checker found all 48 files present and all 48 sha1 values matching. All 48 apply with no error, and the flip is last. The checker noted one gap: the list's header leaves `water-tile-check.patch` off its list of modified files.
- **The sha1 values hold only for the working tree.** Eight patches on the list are untracked and six are modified since the last commit (NB-2).

**The six switches, on main and after the whole list**

| Switch | Main (HEAD) | After the list | Changed? |
| :--- | :--- | :--- | :--- |
| lodgeHold | `data/biomes/brunt.json:51` `"world"` | `"world"` | No |
| heldMul | `data/biomes/brunt.json:5` `1.0` | `1.0` | No |
| repeatMarks | `data/biomes/brunt.json:70` `0` | `0` | No |
| lakeSpill | absent | absent | No |
| lakeDig | absent | absent | No |
| random.enabled (quick-match draw) | no `world.json` on main | `data/biomes/world.json:6` `false` | Not switched on |

One lake data line does land: `data/biomes/field.json:19` `"lakeMax": 8`, from `lake-places-data.diff` (list line 84).

**Left out, and why**

| Left out | Why |
| :--- | :--- |
| Wall-hold data and split, memory-under-model data, heldMul 2.0 | Wall-hold window and GW1c (B-05, B-06, memory-under-model review) |
| gw1b-chase-rebase, camera gw1b-chase-measure | Held for the camera question (B-21) |
| grant-rendering-main, world-menu-merge, a1-world-menu, fore-clamp, calm-tones | They wait with the draw (B-07, B-11, B-12) |
| lake-shore, lake-dig, the GW1c parks | GW1c and GW2 (relief-cap and lake-dig review) |
| `rendering/pending/water-everywhere/water_everywhere.diff` | The same file as World's tile grant (both sha1 `d753545f`), so its content lands through list line 83 |
| Tools' `lake-places-cases` | It applies, but 5 of its 13 cases are for `lakeSpill` (GW2), and they add 5 self-test fails |
| Tools' `world-schema-cases` | Parked for GW1c. With it in, 7 self-test fails (B-10) |

**The lakes are in the list, against the EP's hold.** The records put them in GW1b: `docs/world/planet-stack-recut.md:15` (stage 1, step 7), and `lake-places/README.md` calls lakeMax 8 "the GW1b row". The builder put four lines in their own group (lake-places.diff, the tile grant, the lakeMax data row, water-tile-check) and noted that the EP drops them to keep the hold. Whether those four lines stay in is the EP's call (NM-1).

**Does not apply:** `architecture/pending/gw1b-golden/gw1b-golden.patch` (sha1 `ee5abe01`). It does not apply after meters-zero ("patch failed: sim/core/tools/parity.gd:91"). Before meters-zero it applies, but then meters-zero and gw1b-energy fail. The checker reproduced the failure on the full stack (NB-1).

**Named for GW1b but not parked yet**
- Tools' CI lines for the three director checks and `bounce_count.gd` (B-23).
- Tools' six biomes-world cases on their own (B-10). There are also no cases for lakeMax on its own.
- Simulation's re-cut of gw1b-golden.
- Camera's fight-3 ease. `docs/camera/runs/d55c612f/fight3/findings.txt` says there is no safe camera-side fix: "Until then fight 3 keeps its ceiling (0.111)".
- The lake-water side-by-side that `water-everywhere/README.md:47` asks for, and the launch-cone side-by-side (B-15). Neither was found.

## New findings

The readers filed every new finding as a major. The stand-in raises two of them to blockers, because each one stops the list from being stacked as written. Duplicates from different readers are merged.

### Blockers

**NB-1. Simulation's golden patch does not apply on the GW1b list in any order.**
- **Evidence:** The builder: after meters-zero, "error: patch failed: sim/core/tools/parity.gd:91". Before meters-zero it applies, but then `meters-zero.patch` fails at "parity.gd:90" and `gw1b-energy.patch` at ":4280". The checker confirmed the failure on the full stack (sha1 `ee5abe01...` matches). Cause: the golden was cut on steps 1 to 4 only (its README:39), and meters-zero adds a line inside its hunk.
- **Why it blocks:** the golden carries the arena pins, and its own README records parity, `cross_check`, `cross_end_check` and `frame_check` going red with the flip until those pins are in. The world-sim reader marked the golden's parity run as on record. That run had no riders in it, so it does not contradict this failure.
- **Fix:** Simulation re-cuts gw1b-golden on the list, up to and including intro-store, and re-runs parity with the flip.
- **Owner:** Simulation.

**NB-2. The re-cut parks and their records are not on main. The "commits" the EP cited are sha1s of patch files.**
- **Evidence:** `git rev-parse --verify ee5abe01` fails. The readers found the same for e6214dca, f12828ac, a7eb64f3, aed02606 and 0f8ee10a, and `sha1sum` matches each one to a patch file. `git status` shows these untracked: `planet-stack-recut.md`, intro-store, gw1b-golden.patch, gw1b-pins, bounce-count, ghost-tally-parts, floor-walk-probe.diff, `docs/director/runs/b0e20f9a/`, `docs/rendering/runs/ed1591cb/`. These are modified: `pins-gw1b.diff`, stray-beams, launch-cone, beam-aim-throw, stray-beams-input, water-tile-check. Also `ground-repin.diff` shows as deleted (" D"). HEAD's committed `stray-beams.diff` fails ("patch failed: data/director/interrupts.json:294"), and HEAD's `pins-gw1b.diff` has 25 checks, not 26.
- **Rating:** the readers filed this as a major. It is raised here because stacking from committed files fails today.
- **Fix:** the EP reviews and commits each re-cut park with its records, cites real commit ids, and builds the stack only from committed files. Re-check the 48 sha1 values after the commit.
- **Owner:** EP.

### Majors

| Id | Problem | Evidence | Fix | Owner |
| :-- | :--- | :--- | :--- | :--- |
| NM-1 | The records put the lake parks inside GW1b, against the EP's hold. Every new GW1b proof was taken with them in. | `planet-stack-recut.md:5` and `:15`. `lake-places/README.md:16` "The GW1b data row". `water-everywhere/README.md:5` "in GW1b". `A1-sprint.md:125`. The anim_check pass in gw1b-pins (README:3), the step-up retake (f3e407ec README:3) and water-tile-check (README:16) all ran with the lakes in. `stage1-gw1b-before.txt:1` includes lake-places, and the run without lakes (`gw1b-on-main-b0e20f9a`) has no floor-rise. Three readers and the builder agree. | The EP decides once, in writing. If the lakes stay out: drop list lines 82-85. World re-runs stage 1 without lake-places (floor-rise and floor_walk_probe in). Animation re-runs anim_check, water_tile_check and the step-up picture. Correct the planet-stack page and the lake READMEs. | EP; World, Animation |
| NM-2 | After the flip, 7 mechanics checks and Simulation's 2v2 checks run only on the hand-made arena, which no player sees. No one has classed the rows that fail on the planet. | `gw1b-arena-flip/before-the-arena-pins.txt`: brunt "133 of 134", deepen "86.2 to 17.2 units", repeat "0.0 against 0.0", fill "0 units outward", craters 28 rows, wall 2 rows; memory_model "3 marks". gw1b-golden sets the arena for all of cross_check, cross_end_check and fights_check: "A 2v2 on the planet is World's and Encounter's to cover". | World classes each red row as staging or behaviour. A behaviour row gets a planet-7 row or an owner's ruling before the flip. The EP names an owner and a window for a 2v2 row on the planet. | World, Simulation, Encounter, EP |
| NM-3 | No one owns World's `ground_check` re-pin after the riders. | `checks-gw1a/README.md`: ground-repin.diff "is deleted", after a run with no meters-zero, gw1b-energy or riders. The same README's bisect shows the hashes move with the director's data. gw1b-golden's README table still has World re-cutting ground-repin "just before step 20". The checker confirmed the diff does not exist. | World runs its whole list on the stack with the riders and files either a re-pin or a pass record. Simulation updates its table. | World, Simulation |
| NM-4 | gw1b-riders takes away the golden's only KO. | `goldcmp_b4916fb.txt:9` "match 8  ticks 40833 (DIFFERENT: 43200)", so the match now runs to the cap. `sim/core/tools/golden_recipes.gd:14-15` says that match exists "so the match goldens keep a KO". `gw1b-golden/README.md:42` still calls it "seed 11's KO match". | Encounter explains why seed 11 no longer ends. Simulation picks a seed on the finished tree that ends in a KO and a finisher, before the re-record. | Encounter, Simulation |
| NM-5 | Four of the six rider lanes, and the claim that the base is byte-identical, have no record file. | `docs/director/runs/b0e20f9a/b17-lane` holds only `goldcmp_b4916fb.txt` and `goldcmp_4000908.txt`. README:20, :22-23 and :25-26 claim "byte-identical", "identical", "moves both human-input replays" and "checkpoints 117 and 61" with no file behind them. | File the golden comparisons for the base, index-stage, wall-cone, stray-beams and beam-aim-throw in the same format. | Encounter |
| NM-6 | `floorlift_check` (run in CI, `.github/workflows/ci.yml:634`) has no record on the GW1a tree with floor-rise and floorlift-rise in. | `planet-stack-recut.md:59` "Not built in these trees ... (floorlift-rise, ...)". `floorlift-rise/README.md:29` was run on `4327cfbb`. **Note:** the builder's list includes floorlift-rise (line 69, before World's floor grant), so the list and the planet-stack page differ here. It applies, but it has not been run. | Run floorlift_check on the stacked tree and file it. The EP keeps floorlift-rise before or with World's floor grant. | Encounter, EP |
| NM-7 | Controls' re-stage hides a real mismatch inside a brawl. From a pad, B pressed 12 ticks after RT during a brawl still fires the beam. | `b17gold/recut_stray_beams_input_test.txt` "FAIL  window: RT, then B 12 ticks later ... is the heavy, no beam: [... \"beam_fire\"]". `stray-beams-input.patch:61-62` now waits for an idle fight. `stray-beams/README.md:23` "a hit-stop doesn't eat the window". | Keep the idle rows. Add a row inside a brawl that states the intended result. Encounter and Game Design rule whether a hit-stop stretches RT's window from a pad, and the READMEs say so. | Controls, Encounter, Game Design |
| NM-8 | On the default planet, the floor rise lifts a walking fighter about 13 body heights in 5 ticks at a lake edge. The fix is not in GW1b. | `docs/animation/water-tile-check.md:34` "118, 184, 184, 184 and 169 units on five ticks, about 13 body heights". `lake-shore/README.md:3` "837 units over 5 ticks". `planet-stack-recut.md:47` puts lake-shore in stage 3. `water-tile-check/README.md:22` "--shore fails on GW1b's data". The step-up ruling and picture cover a 62.8-unit lift only. | Either lake-shore and its data row join GW1b before the flip, or the EP records that GW1b ships this jump knowingly, after Game Design re-reads its ruling (`docs/design/buildings.md:329`). | World, Game Design, EP |
| NM-9 | ghost-tally-parts edits Rendering's `sim_host.gd` with no Rendering approval on record. Its README says nothing changes on screen, then admits VFX's ghost budget can differ by one. | `ghost-tally-parts/README.md:7` (the grant) and `:13`. A search of `docs/rendering` finds no answer. The run record `docs/vfx/runs/ed1591cb/ghost-tally-parts.txt` is untracked. **Placement differs:** the reader puts it straight after gw1b-energy; the builder's list puts it in the look group (lines 89-90). Both orders apply. | Rendering files its approval. VFX states the one-ghost change plainly. If the EP rules it visible, add a short side-by-side. | VFX, Rendering, EP |

**Where the results disagree**
- **Tested commit.** The builder used `dce749fc`, the checker `5bf9ff46`, and main is `575bf093`. None of the files changed between them is on the list.
- **`check-scripts-table`.** One reader reports a run on an export (58 unreviewed). The builder and another reader say it cannot run there, and the tool calls `git ls-files`. The 58 is unconfirmed (B-23).
- **Self-test totals.** They differ across trees (10140/10141, 10122/10123, 10135/10136). Every tree has the same one failure (B-10).
- **floorlift-rise.** It is in the builder's list, but the planet-stack page says it was not built in World's trees (NM-6).
- **Lakes.** The records and the builder's list put them in GW1b. The EP's stated hold keeps them out (NM-1).

## Still missing before the flip

1. A gw1b-golden re-cut that applies on the list, with parity re-run (NB-1).
2. Every re-cut park and record committed, with the list rebuilt from committed files (NB-2).
3. The EP's written decision on the lake parks, with the proofs re-taken to match (NM-1). If the lakes stay out, also a ruling on the lake-edge jump (NM-8).
4. Tools' six biomes-world cases, so CI's self-test is green (B-10).
5. CI lines or reasons for the new checks, then `check-scripts-table --check` run inside a repository (B-23).
6. One full gate with the mode on planet across the owners, and the golden re-recorded on the finished tree with a KO seed (B-02, NM-4).
7. Class for each planet red row of the 7 mechanics pins, an owner for a planet 2v2 row, and World's ground_check result with the riders (NM-2, NM-3).
8. Lane records for the base and four riders (NM-5), and floorlift_check on the stacked tree (NM-6).
9. Side-by-sides in the default look for launch-cone and lake water. The step-up picture fixed (B-08, B-15). The EP looks at B-20's GIFs.
10. Answers on record from Tools (dropOnPress), Narrative (meters.json) and Controls (join-press) (B-24). Rendering's approval for ghost-tally-parts (NM-9).
11. The untracked `docs/animation/step-up.md` removed or staged before step-up lands (B-44).

## How this was done

- Read the first review (`docs/ep/reviews/GW1b-review.md`), the parks under `docs/*/pending/`, World's planet-stack page and the related reviews (lake fixes, memory under model, relief cap and lake dig).
- Three readers checked the earlier findings by area: world and sim, director and controls, look and the rest. They used `git log`, `git status`, `git grep`, `sha1sum` and `git apply --check` on clean exports. They ran on the cheaper model, and the stand-in still has to check their findings.
- The builder wrote `docs/ep/reviews/GW1b-stack.txt` by applying each patch for real, in order, on two fresh `git archive` exports. Then it ran `validate.js`, its self-test and `world-checks --verify` with node.
- A separate checker re-applied the 48 lines on its own export, compared each sha1, and read the six switches on main and on the stacked export.
- The stand-in spot-checked the commit difference (`git diff --stat dce749fc HEAD`), the status of the untracked files, that `ee5abe01` is not a commit, and that `tools/check-scripts-table.mjs:23` calls `git ls-files`.
- Nothing was run in Godot or in a browser. No file in the repo was changed except this page. Safety numbers in B-20's record were not judged.

Cost: about 1.0M tokens on the cheaper model (three verdict readers, the list builder, an independent list checker and a writer), plus the stand-in's own checks below.


## The stand-in's own checks (2026-11-21, about 03:20)

Done by hand after the readers finished, on main at 575bf093.

| Check | Result |
| :--- | :--- |
| The apply list **without the four lake lines** (the two `lake-places` diffs, the tile grant and `water-tile-check.patch`), on a fresh clean export | **44 lines tried, 0 failed.** The flip goes on last and `data/biomes/world.json` ends at `"mode": "planet"`; no `lakeMax` key is added. So the list works with the lake group in or out, and the EP's hold on the lakes does not need a re-cut of anything else |
| NB-2's example: is `ee5abe01` a commit? | No: `git cat-file` answers "Not a valid object name". It is the sha1 of the patch file, as the list records it |
| Both output files screened for absolute paths | None |

Not re-done by hand: the failure of `gw1b-golden.patch` at `sim/core/tools/parity.gd:91` (NB-1). The list builder and the independent checker each found it on their own export, with the same error line.

Which lines to drop if the lakes stay held: the four `ap` lines of the lakes group in `docs/ep/reviews/GW1b-stack.txt` (the group between the floor rise and the look patches).

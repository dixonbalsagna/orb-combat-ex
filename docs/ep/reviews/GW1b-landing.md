# GW1b landing review (2026-11-21)

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **When:** 2026-11-21, after the re-check of 03:20 (`docs/ep/reviews/GW1b-recheck.md`).
- **What:** the 55-line GW1b stack (the "ap" lines of the EP's stack script), applied in order on main HEAD `54187710` ("World: GW1b checks re-read ...", 2026-11-21 09:41). GW1b makes the round planet main's default world. The *flip* is one data line that sets `data/biomes/world.json` mode to "planet". The *riders* are the small rule changes that go with it.
- **How:** read-only. The list was applied on a clean `git archive HEAD` export in the stand-in's scratch folder, never on the repo. Nothing was run in Godot or a browser. Node checks ran on the export. The EP's gate record (full run), fix record (after six gate fixes) and World's check-list log were read, not re-run. Two pin readers and a guard sweep ran on the cheaper model. The stand-in re-read the evidence for every blocker and for both pins the EP accepted.
- **Words used once:** a *park* is finished work waiting in `docs/<area>/pending/`. A *pin* changes a check's expected value, set-up or scope so it passes on the new tree. It is *honest* when it re-bases to the intended behaviour with evidence. It *hides a fault* when it re-bases a regression, weakens an assertion, or moves a check off the planet with no planet row and no owned follow-up. A *planet row* is a check row that proves the same thing on the planet. *Staging* is a check's own set-up (where it puts the fighters).

## Verdict

**Land after named fixes. Do not land as stacked.** The list applies cleanly, the flip is in the right place and no play-first switch is on. But three blockers need fixing first, and each fix is small: VFX's trail bar must stay at 0.99; split_sweep's opening and intro rows must not be pinned to the arena without a planet row; and Camera's two visible changes need their side-by-sides on file.

## The three questions the EP asked

### 1. Is every pin or re-stage in the last seven parks honest?

**No. Two are not.** split_sweep's arena pin covers rows about the game's own opening, which fail on the planet (C-1). hash_check's trail bar is lowered on evidence that CI's own run contradicts (V-1). Five more split_sweep rows are not classed (C-3). The other pins are honest, some with a named follow-up owed.

| Park | Check and row | What changed | Honest? | Why | What covers the planet |
| :-- | :-- | :-- | :-- | :-- | :-- |
| camera gw1b-split-sweep | split_sweep: opening default | moved to the arena (`WorldPin.arena` in `_initialize`) | **No, hides a fault** | Bare `newMatch`, the game's skip start, no place staged. Planet: 0.047 of screen height against the 0.075 bar | Nothing. The real-match rule is about 0.033 |
| camera gw1b-split-sweep | intro resize double_drop 0/48, intro real, intro composed | moved to the arena | **No** | The sim's composed intro, which the game plays by default (`render/core/main.gd:426-440`). Planet: a fighter off the screen | Nothing |
| camera gw1b-split-sweep | launch split 26718 / 45606 | moved to the arena | Not classed | Posed at fixed x, y 40, no place. 2 and 1 safety cuts on the planet | Nothing asserts `lag_cuts` on the planet |
| camera gw1b-split-sweep | depth foreground, one view and split | moved to the arena | Not classed, likely staging | Posed y 40 plus a staged `building_hit`. Off screen 68 and 64 ticks (bound 52) | launch_shots_check on planet 7, not this bound |
| camera gw1b-split-sweep | arena turn, one view | moved to the arena | Not classed | `arena_turn` is a sim event (`sim/world/epoch.gd:786`). Framing not restored | Nothing |
| camera gw1b-split-sweep | crossing start, crossing start staredown 72 | moved to the arena | Yes | Asserts `WorldLanes.avenueAt`, the arena's avenue | n/a (arena feature) |
| camera gw1b-split-sweep | dolly drift to the back street, dolly launch across a street | moved to the arena | Yes | Streets and plane size of the hand-made city | n/a (arena feature) |
| camera gw1b-split-sweep | other staged rows | moved to the arena (they passed on the planet) | Yes in form | Posed scenes | Real matches on the planet |
| camera gw1b-split-sweep | real match rows | `WorldDefault.setForTest(data mode)` per match | Yes | They play the planet | Themselves (13 rows, pass after the fix) |
| camera gw1b-split-sweep | `_sim_unchanged` (rig never changes the sim hash) | runs on the arena | Yes | The rig only reads S | `render/tools/determinism.gd` runs the main scene, SplitRig included, on the planet in CI (`.github/workflows/ci.yml:433`) |
| camera gw1b-split-sweep | split_rig wide hold | dwell 0 at the drawn floor | Real fix, but no side-by-side (C-2) | Real match 3 human 1: 71 to 12 under the line | Real matches on the planet |
| camera gw1b-camera-checks | swing_places_check, 3 rows | moved to the arena | Yes | Builds its own turned frame and poses a landmark on the arena | swing_fight_check plays planets (`swing_fight_check.gd:24`), swing_real_check |
| camera gw1b-camera-checks | split_vision_check merge row | seeds [12345, 2] to [12345, 2, 5] | Yes | Bigger sample, same "two merges" bar | Itself (planet) |
| camera gw1b-camera-checks | chase_rush_check seed 2, 4 taps | tap gap 35 to 55 ticks | Camera rows yes; the sim change is unowned (C-4) | 35, 70 and 90 give 2 catches; only 45 to 55 pass | Itself (planet 7, touch 2) |
| camera gw1b-camera-checks + handover-ease | cross_ko_check first KO jolt | ceiling 0.094 added, then removed; anchor ease added | Yes, the game made right | Jolt 0.093 to 0.010 (fix log). No limit loosened. Reads S only. No side-by-side (C-2) | Itself, plus all 15 camera checks pass |
| audio world-check-arena | world_check, 27 rows (bed, height, surfaces, biomes, soils, water, hash rows) | `WorldPin.arena()` at the top of `_run` | Partly (A-1) | Staged spots on arena biomes; the sound set is off in data. Its "planet section" is generation 2 at 2,400 columns, not planet 7 generation 3 | Generation-2 ring rows only |
| net gw1b-planet | desync digest (`net/desync.gd:122-129`) | the digest also reads each fighter's `act.dirI` | Yes (wider, not looser) | net/ only; SimHash already hashes dirI (`sim/core/hash.gd:212`). The spectator negative control now catches 3 of 3. PROTO not bumped (N-1); other fields still unread (N-2) | The spectator control runs on the planet |
| net gw1b-planet | desync_check "director" injection (`net/tools/desync_check.gd:146-147`) | on a field world, `dirS.stop` instead of `dirS.cool` | Yes | The sim resets the cool-down before the next checkpoint, so nothing could be detected; `stop` is in the digest and persists. The arena keeps `cool` | The injection runs on the planet; after-fix control 9 caught, 0 missed |
| vfx gw1b-pins | effects_check biome effects, 8 rows | run under `WorldPin.arena()`, world restored after | Yes | Spots are arena x values; on the planet they hit the sea | New `_biome_fx_planet`: 7 rows on a real desert, forest and mountain |
| vfx gw1b-pins | effects_check meteor turn | planet row expects every point kept; the old drop rule runs on an arena sim | Yes | `render/vfx/meteor.gd:716-718` keeps planet-direction points by design | The planet row itself |
| vfx gw1b-pins | hash_check "effects ran" (`render/vfx/tools/hash_check.gd:88`) | `max_k >= 0.99` to `>= 0.9` | **No, guard loosened (V-1)** | CI's seed list reads 1.00 on this stack | CI hash_check with seed 1 on the planet, at 0.99 |
| world gw1b-checks-reread | wall_check, 8 rows | `WorldPin.launchTravelOld()` (travel 2.0 in memory) | Yes, as staging | The 3,000-unit staging can't reach the tower at 1.5. The rows assert wall rules after impact, not reach. No row at shipped 1.5 (W-2) | None here; wall_check is arena-pinned since GW1a |
| world gw1b-checks-reread | wall_hold_check slams, freeze, push | `launchTravelOld()` before `WorldPin.shipped(model)` | Yes, as staging | Push ceiling measured at a faster impact, so conservative. Label "Orb's real path" now inexact (W-2) | None here; arena towers |
| world gw1b-checks-reread | beam_grid_check, 3 rows | `a.powerPress = true` on the RT+B step | Yes | Matches the stray-beams rule and `beam_front_check.gd`. No tolerance moved | Already on planet 7 |
| world gw1b-checks-reread | ground_check planet7/2400 hash | `5b60d7a246a76524` to `36fae547f71e0607` | Not proven (W-1) | No bisect for this row | The row itself, once its cause is named |

**Gate records.** The full gate record had ci_split_vision, ci_world_check, ci_cross_ko, ci_swing_places and ci_chase_rush red, and World's list red on ground_check, beam_grid_check, wall_check and wall_hold_check. The fix record shows every line at exit 0, but its exit column cannot show a failure (G-1). The fix logs' own verdict lines do show a pass for each camera, audio, VFX and netcode check. The fix record has no world-checks line. World's check-list log was still running at 09:56: 49 groups done, all "0 check(s) failed", ground_check passing with the re-pin, and the wall and beam_grid checks not yet reached. World's own record (`docs/world/runs/gw1b-checks-reread/s426-copy-with-the-four-fixes.txt`) says 90 checks, 0 red.

### 2. Does anything on the list loosen a guard?

**Yes, three things.** VFX's trail bar (V-1), parity's curve row moving to the arena (GS-2), and the water-tile re-cut taking its failing places out of the gate (GS-3). No CI line, world-checks row or schema bound is removed or widened.

**The two pins the EP accepted:**

- **VFX's trail bar: no, the stand-in disagrees.** CI runs hash_check with no seed flag (`.github/workflows/ci.yml:494`), so it uses `var seeds: Array = [12345, 4, 7, 1]` (`render/vfx/tools/hash_check.gd:23`). The file says seed 1 "reaches a full trail (1.00)" (`:22`). The EP's own full gate record and fix record on this stack both read "max trail strength 1.00" and pass at 0.99. VFX's 0.97 comes from a run with seeds 12345, 4 and 7 only (`docs/vfx/runs/4052d67d/gw1b-s426-effects-hash.txt:7`). So the README's reason ("the real matches peak at 0.97") is false for the check CI runs.
- **World's launchTravelOld: yes, the stand-in agrees.** World's bisect (`docs/world/runs/gw1b-checks-reread/the-four-reds-and-the-bisect.txt:18`) shows `grant-data-gw1b.patch` alone turns 6 rows red and the pin clears them. The assertions are unchanged, and the value stays inside the data's travel range. The readers differ on what is owed. One says a row at the shipped 1.5 would be better but is not required; the other asks for it as a follow-up. The stand-in keeps it as a MAJOR (W-2), because no wall rule (stagger, lodge, push ceiling) is asserted at the shipped travel on any world.

**Loosened and doubtful rows, in full:**

| Patch | File:line | Before -> after | Verdict | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| vfx/gw1b-pins | `apply.patch:142`, hash_check.gd | `max_k >= 0.99` -> `>= 0.9` | Loosened, evidence contradicted (V-1) | 0.97 is from a 3-seed run; CI's 4 seeds read 1.00 |
| architecture/gw1b-golden | `gw1b-golden.patch:198`, parity.gd | `_shared` on the planet -> `_arena(_shared)` | Loosened, no planet row (GS-2) | README:51 "(256 against 257)"; `sim/core/flight.gd:183` feeds the camera cue |
| animation/water-tile-check | `water-tile-check.patch:89`, README:15 | 4 failing dry places -> ungated "shallow" pin; lake (17 places, up to 683.8) and shore printed only | Loosened, thin follow-up (GS-3) | Water floor on in `data/biomes/water.json:64-66` |
| tools/gw1b-ci-lines | `gw1b-ci-lines.patch:121`, check-scripts.json | water_tile_check NOT RUN | False reason (GS-3) | Says dry "fails by itself"; Animation's README:13 says dry passes |
| world/floor-rise + director/floorlift-rise | `floor-walk-probe.diff:9`, `floorlift-rise.diff:51` | the floor's own rise is subtracted | Re-base, but with GS-3 no gate sees the lake-edge lift | `buildings.md:329` keeps the one-tick lift uncapped |
| world/gw1b-checks-reread | `.diff:18`, ground_check | planet7/2400 hash re-pinned | Re-base, thin (W-1) | The bisect covers wall and beam_grid only |
| world/gw1b-checks-reread | `.diff:27,39,47`, wall_check, wall_hold_check | travel 1.5 -> 2.0 in memory | Re-base, accepted (W-2 follow-up) | Bisect record line 18 |
| architecture/gw1b-golden | cross_check, cross_end_check, fights_check | whole check -> arena | Scope move; NM-2 still open | README: "2v2 on the planet is World's and Encounter's to cover", no date |
| director/launch-cone | launch_cone_check:188 (new) | 0 aimed -> NOTE and pass | Doubtful (new check, nothing loosened) | CI gate on this stack measured 1 aimed |
| camera/gw1b-camera-checks | chase_rush_check:10 | 35 -> 55 ticks between taps | Re-stage over a sim change (C-4) | 35 -> 2, 45 -> 3, 55 -> 4 catches |

**Counted, not listed:** 6 rows tighten (arc_check and beam_ai_check ceilings, index-stage, cross_ko net, the scape-side and keep-human ceilings, the net digest, floor-rise-unpin). 17 rows are re-bases or re-stages with evidence (parity's 9 no-planet rows, golden_recipes, frame_check, the last stand, meters-zero, gw1b-energy's parity and power_check rows, bystanders, swing_legal, bark_reads, knock_wall, split_vision, beam_grid, the arena-pin group with planet rows, and the schema and CI additions). About 12 data-value hunks are rule changes, not guards.

### 3. Does the list apply in order on main HEAD?

**Yes. All 55 of 55 lines apply on a clean export of `54187710`,** with no failures, no fuzz and no conflict markers. Plain `git apply` was used, without the script's `--3way`. 13 lines apply at an offset. The tree then differs from HEAD in 101 files (+8265 / -6606). The flip is line 47. After it come only Simulation's golden patch, the script's own copy of `docs/sim/runs/c860b5a7/gw1b-target/golden-target.json` over `sim/core/test/golden.json`, and check files (Camera, Audio, Netcode, VFX, World). Nothing after the golden touches `data/` or the golden.

- **Uncommitted patch files:** none. All 55 patch files and the golden-target copy are tracked and clean, so a landing uses the bytes that were tested.
- **Modified park READMEs (not patches):** `docs/animation/pending/step-up/README.md` (+4) and `docs/camera/pending/gw1b-camera-checks/README.md` (1 line).
- **B-44 trap still open:** `docs/animation/step-up.md` is untracked in the working tree, and `step-up.patch:212` creates it. On the real tree the apply fails with "already exists in working directory". The untracked copy is byte-identical to what the patch creates. Remove it before applying.
- **Node checks on the export:** `node tools/validate.js --self-test` 10148 of 10148 (main 10116); `node tools/validate.js` 323 files, 0 errors, 2 warnings; `node tools/world-checks.mjs --verify` ok, 90 in CI (main 87). B-10's self-test failure is gone.
- **Since the 48-line list:** the 3 lake lines are out; water-tile-check is re-cut (the only changed sha1); biomes-world-cases and gw1b-ci-lines are added before the flip; gw1b-golden and the seven new parks come after it.

**Switches (main -> stacked export):**

| Switch | File:line | Main | Stacked | Play-first? |
| :-- | :-- | :-- | :-- | :-- |
| world mode | `data/biomes/world.json:4` | (file absent) | "planet" | The flip |
| quick-match draw `random.enabled` | `data/biomes/world.json:6` | (absent) | false | Off |
| lodgeHold | `data/biomes/brunt.json:51` | "world" | "world" | Off (unchanged) |
| heldMul | `data/biomes/brunt.json:5` | 1.0 | 1.0 | Off (not 2.0) |
| repeatMarks | `data/biomes/brunt.json:70` | 0 | 0 | Off |
| wallRebound / wallStop / wallDepthHold | `data/biomes/brunt.json:48-50` | 0.25 / 1.0 / 0 | same | - |
| lakeSpill, lakeDig, lakeMax | `data/biomes/field.json` | absent | absent | Off (no file names them) |
| flight.flatOut | `data/fight/power.json:108` | 5000.0 | 3500.0 | Rider |
| launchTravel | `data/fight/power.json:110` | 2.0 | 1.5 | Rider |
| dash closeSec (1000/3000/6000) | `data/fight/power.json` | 0.4 / 0.8 / 1.4 | 0.45 / 1.0 / 1.9 | Rider |
| step_up enabled | `data/anim/ground_motion.json` | (absent) | true | Rider |
| dropOnPress | `data/director/interrupts.json` | (absent) | true | Rider |
| wallCone / wallBy | `data/director/launch.json` | (absent) | 20.0 / "trueDistance" | Rider |
| anguish | `data/director/swing.json` | 2.0 | 0.0 | Rider |

## BLOCKER

| Id | Park | What is wrong | Evidence | Fix | Owner |
| :-- | :-- | :-- | :-- | :-- | :-- |
| C-1 | camera/gw1b-split-sweep | The arena pin moves split_sweep's opening and intro rows off the planet. Both fail there, no planet row covers them and nobody owns the gap. The README's reason is false for these rows: they stage no place. | `split_sweep.gd` `_opening_default` runs `SimCore.newMatch(_S, 3, {"p1": true, "p2": true})` and requires `min_size >= 0.075` (`:3406` on the export). Planet log: "a fighter only 0.047 of the screen height"; intro resize: "a fighter off the screen". README:14: "on the planet those places aren't there". The real-match rule is about 0.033 (`:4707`). | Take these rows out of the pin or add planet-7 copies. Then fix the planet opening's framing, or set a ceiling with an owner and a date. Correct the README. | Camera |
| C-2 | camera/gw1b-handover-ease + gw1b-split-sweep (wide hold) | Two visible camera changes have no side-by-side in the default look on file (ADR 0010), and no flash-mode record exists for either. | `gw1b-camera-checks/README.md`: "It's a small visible change, eased, with no cut and no fade." The only records are numbers: `docs/camera/runs/c860b5a7/gw1b-handover-ease/runs.txt`, `.../gw1b-split-sweep/runs.txt`, `one-view-before-after.txt` (layout changes 9 to 13). | One side-by-side per change on the stacked tree, same seed: the cross_ko first-KO handover, and real match 3 human 1 for the wide hold. Add the flash-mode record. The EP looks before landing. | Camera (capture window) |
| V-1 | vfx/gw1b-pins (hash_check hunk) | The "effects ran" bar is lowered from 0.99 to 0.9 on false evidence. CI's own run on this stack reads 1.00. A guard loosened without evidence. **The readers differ on severity:** the pin reader calls it a BLOCKER, the guard sweep (GS-1) a MAJOR. The stand-in rates it a BLOCKER under this review's rule; the fix is one hunk. | `apply.patch:142` `>= 0.9` (was `>= 0.99`). `hash_check.gd:23` default seeds include 1; `:22` "Seed 1 reaches a full trail (1.00)". `ci.yml:494` passes no seeds. Gate and fix records: "max trail strength 1.00", pass. VFX record `docs/vfx/runs/4052d67d/gw1b-s426-effects-hash.txt:7` uses seeds 12345, 4, 7 only. | Drop the hash_check hunk and keep 0.99. Land effects_check as it is. Correct the README's threshold section. | VFX (the EP strips the hunk) |

## MAJOR

| Id | Park | What is wrong | Evidence | Fix | Owner |
| :-- | :-- | :-- | :-- | :-- | :-- |
| C-3 | camera/gw1b-split-sweep | Five pinned rows are not classed and have no planet row: launch split 26718 and 45606, depth foreground (one view and split), arena turn. "No safety cut in a launch" is asserted only here. | `split_sweep.gd:1002-1004` poses at ax 60000, y 40. Planet: "launch split 26718: 2 safety cuts in a launch"; "arena turn ... did not come back to its framing". | Class each row as staging or a fault. Add a planet row asserting `lag_cuts == 0` in a split launch, or name an owner and a date. | Camera |
| C-4 | camera/gw1b-camera-checks (chase_rush) | The re-stage hides a gameplay change: under GW1b's data a 4-tap chase catches only twice at 35, 70 or 90 ticks. Nobody in Game Design or Combat has signed it off. It fails without the flip too, so the riders' data is the cause. | `chase_rush_check.gd:230` `catches >= chain - 1`; patch `_one(2, 0, 0.7, 4, 55)`; runs.txt: gap 35 "2 catches", 55 "4", 70 "2", 90 "2". | Write down the narrower catch window and route it through the EP to Game Design or Combat. Keep the 35-tick row as a printed reading. | Camera (route via EP) |
| A-1 | audio/gw1b-recut (world-check-arena) | All 27 planet failures go to the arena, including the sim-hash rows. The "planet section" the README cites is a generation-2 ring at 2,400 columns, not planet 7 generation 3. The planet re-cut is "if wanted", with no owner. Lower risk: the sound set is off. | `audio/tools/world_check.gd:743,756` `"planetGen": 2`, `"cols": 2400`. README: "a bigger job for after the flip, if wanted". `audio/data/world_cues.json:4` `"enabled": false`. | Correct the README. Add one generation-3 planet-7 row (bed starts, sim hash unchanged with the set on), or make it a follow-up that must close before the set is switched on. | Audio |
| N-1 | net/gw1b-planet | The checkpoint digest changes but PROTO stays 5 (so do desync-marks and desync-fdmg). Two builds with the same data and different digests pass the handshake, then report false desyncs. GW1a and GW1b peers are still refused by the data hash, so this landing itself is safe. | `net/handshake.gd:21` `const PROTO: int = 5` (unchanged on the export); `net/desync.gd:122-129`; key is `seed|ai|setup|dataHash` (`handshake.gd:115`). | Bump PROTO to 6 with a comment, now or as a named follow-up before the next LAN build. | Netcode |
| N-2 | net/gw1b-planet | The dirI gap is closed, but SimHash still hashes fighter fields the digest never reads (act scalars, act.queue, f.splashed, f.style and others). A divergence that lives only there goes unseen at checkpoints, as dirI did for 270 ticks. | `sim/core/hash.gd:197-220`; `net/desync.gd:70-79` reads `SimHash.FIGHTER` fields only; `:161` containers append `-2.0`. | Add the remaining fields to the digest with a control each, or write why each is left out into rollback.md. | Netcode |
| W-1 | world/gw1b-checks-reread (ground_check) | The default planet's gen-1 hash is re-pinned with no named cause. World's bisect covers wall and beam_grid only. | `sim/world/tools/ground_check.gd:9` `"planet7/2400": "36fae547f71e0607"`; bisect record line 18 has no ground_check step. | Bisect the move to its patch (the director riders are the likely group) and write the cause into the BASE comment and the run folder. | World |
| W-2 | world/gw1b-checks-reread (wall_check, wall_hold_check, pin.gd) | The staging pin is honest, but afterwards no wall row runs at the shipped travel of 1.5, and wall_hold_check still labels its model-on pass "Orb's real path". (The guard sweep calls the extra row optional; see question 2.) | `sim/world/tools/pin.gd:46-48` `SimPower.launchTravel = 2.0`; `data/fight/power.json:110` 1.5; `wall_hold_check.gd:145`. | Add one wall_check row at 1.5, staged closer (about 2,250 units), proving a tier-1 wall outcome and the push ceiling. Reword the label. | World |
| GS-2 | architecture/gw1b-golden (parity.gd) | Parity's curve row now runs only on the arena, because on the planet `predict()` lands one tick early. `predict()` sets the camera's launch cue and the planner's timing, so the mismatch is in the default world. No planet row, no follow-up. | `gw1b-golden.patch:198` `_arena(_shared)` (export `parity.gd:108`); README:51 "(256 against 257)"; `sim/core/flight.gd:183`. | Keep the exact row on the arena and add a planet row within 1 tick on planet 7 / gen 3, or make `predict()` read the same ground. Name the follow-up in the README. | Simulation |
| GS-3 | animation/water-tile-check + tools/gw1b-ci-lines | The 4 failing dry places become an ungated pin; lake (17 places, up to 683.8 units) and shore rows are printed only; the check is not in CI. With the floor on and the lake parks held, fighters on the planet stand over undrawn lakes, and no gated row sees the lake-edge lift. Tools' not-run reason contradicts Animation's record. | `water-tile-check.patch:89` "GW2 PINS"; `data/biomes/water.json:64-66` `"enabled": true`; `gw1b-ci-lines.patch:121` "fails by itself" against Animation README:13 "dry 157 places, 1.8 at worst". Carried from NM-1 and NM-8. | The EP names the follow-up in writing (World's lake-places, Rendering's water-everywhere) with a target window. Tools corrects the reason and wires the green default line into CI. | EP (follow-up), World, Tools, Animation (README) |
| G-1 | EP gate records | The exit column in the fix record (and the render lines of the full record) cannot show a failure: `$?` holds `basename`'s status. The full record shows split_sweep at 0 while its log says "split sweep FAILED (23)". The fix logs' own verdict lines do pass, so the results stand. | Runner echoes `"$(basename $t) $? ..."`; `false; echo "$(basename /a/b) $? x"` prints `b 0 x`. | Capture `rc=$?` right after Godot, or cite the logs' verdict lines as the landing evidence. | EP |

## Confirmed fine

1. All 55 lines apply in order on a clean export of `54187710`, with no fuzz and no conflict markers; every patch file is committed.
2. The flip is the only line that changes `world.json` mode, and nothing after the golden touches `data/` or the golden.
3. No play-first switch is on: lodgeHold "world", heldMul 1.0, repeatMarks 0, no lakeSpill or lakeDig anywhere, quick-match draw off.
4. No CI line, world-checks row, check-table row or schema bound is removed or widened; the GW1a ceilings tighten or go.
5. handover-ease writes no sim state and loosens no limit; cross_ko is back at JOLT_LIMIT with jolt 0.010.
6. Netcode's gw1b-planet widens the digest without touching a sim file, and the negative controls still catch every break.
7. VFX's effects_check pins keep the arena rows and add real planet rows (7 plume rows and a meteor row).
8. World's beam_grid re-stage matches the stray-beams rule and is already staged on planet 7; the bisect proves the wall-check cause.

## How this was done

- The apply test exported HEAD with `git archive`, then ran `git -c core.autocrlf=false apply --check -v` and `apply -v` for each of the 55 lines in the script's order, plus the script's golden copy. Node checks ran on that export.
- Two pin readers (Camera and Audio; Netcode, VFX and World) and one guard sweep read every patch, README and run record in the stack, and the gate records.
- The stand-in re-checked by hand: the hash_check bar, its default seeds and CI's call; the split_sweep opening row, its bar and the README's claim; PROTO on the export; parity's `_arena(_shared)` line; the ground_check re-pin and the bisect record's coverage; and the tail of World's check-list log at 09:56.
- Nothing was run in Godot or a browser, and nothing in the repo was changed except this page.

Cost: about 0.8M tokens on the cheaper model (an apply test, two pin readers, a guard sweep and a writer), plus the stand-in's own spot-checks of the three blockers.

## The stand-in's own checks (2026-11-21, about 10:00)

The three blockers were re-opened by hand after the readers finished.

| Blocker | What I read | Result |
| :--- | :--- | :--- |
| C-1 | `render/camera/tests/split_sweep.gd:3417-3445`: "opening default" starts a plain match with no staged place (`SimCore.newMatch(_S, 3, {"p1": true, "p2": true})`) and asks for a fighter at least 0.075 of the screen's height. Camera's own record on the planet, `docs/camera/runs/c860b5a7/gw1b-split-sweep/runs.txt:18`: "FAIL  opening default: a fighter only 0.047 of the screen height", and `:15`: "intro resize ... a fighter off the screen a few seconds into the match". The park's README:14 gives one reason for all the pinned rows: "They stage places, streets, depths and turns on the arena; on the planet those places aren't there" | **Holds.** These two rows stage nothing, so the reason does not cover them. They describe the first seconds of an ordinary match on the world the game will now start on, and the pin moves them to the arena |
| C-2 | The handover and wide-hold records named in the table above | **Holds as written:** numbers only, no picture on file. Not re-searched beyond the folders the page names |
| V-1 | `render/vfx/tools/hash_check.gd:22-23`: "Seed 1 reaches a full trail (1.00) ... and the check wants 0.99", with `seeds = [12345, 4, 7, 1]`; `.github/workflows/ci.yml:494` runs the check with no seeds named, so CI plays seed 1. `docs/vfx/pending/gw1b-pins/apply.patch:141-142` lowers the bar to 0.9; its README:11 says real matches "peak at 0.97" | **Holds.** The check's own default set still reaches the bar, so the lower bar is not needed. On the EP's question: I would not accept this pin. It is one hunk to drop |

On the second pin the EP accepted, World's `launchTravelOld`: I agree with accepting it, with a wall row at the shipped 1.5 owed as a follow-up (W-2).

Severity note: C-1 is the one that matters to a player. V-1 costs nothing to fix and does not touch the game itself; it is rated a blocker only because this review's rule is that a guard is not loosened without evidence.

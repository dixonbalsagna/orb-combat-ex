# Prop reach, the zip.price lead, a cheaper logOf (Encounter, local, 2026-10-28)

Brief: `docs/ep/cloud-briefs/encounter-prop-reach.md`, run locally (the EP's brief of 2026-10-28: cloud sessions are
retired). Edited in the shared tree, Encounter's paths only; the one line outside them is a park. Gates ran in scratch
exports: main **782aeef4** with these files laid over it, and again on **19dcd72d** (main moved: Controls' hold or
toggle) for validate, parity, determinism off and on, every input test, loader_check and the probes.

## SUMMARY
1. **PROP SMASH reaches its prop.**
   - The planner aims PROP SMASH the way BUILDING SMASH aims: it plays the send's flight with World's own step, tick by
     tick, and offers PROP SMASH only when that flight breaks a prop on the line ahead.
   - It tries the row's force first, then the forces of a new data row, `aimFm` (Combat's line, parked).
   - On a new probe of 48 launches on 12 gen 2 planets:
     - main: 39 broke their prop, 7 ended short, 2 passed over;
     - now: 47 broke it and none ended short or over on the predicted path.
   - The 48th left the predicted path before the prop: rubble rose under it mid-flight (RISKS 1).
   - World's `flighthooks_probe` prop line reads 10 of 10, none short, none over.
2. **The zip.price lead is not a price bug.**
   - In QA's seed 105 (gen 2, planet 17, touch 2), the light zip at tick 31232 printed "20 ki".
   - In the same tick a bolt hit the zipper in his guard. A hit in guard drains 8% of its damage in ki (22.84 × 0.08 =
     1.83), and he regenerated 0.06. 20 + 1.83 − 0.06 = 21.77, which is QA's figure.
   - QA's record had no printed price for it because the zip ended in the tick it started (NEEDS 2).
3. **A cheaper `logOf`.**
   - `f.act.dirI`, `k % RING` and the up tick are read once per entry, and `kindOf` is inlined.
   - A micro-bench gives 42 to 21 µs a call on a full log, with the same output on 6 logs.
   - tick_hash is byte-identical over 43,200 ticks, and rollback_check passes in every CI mode.
   - dir_prof: see TICK NUMBERS.
4. **planDefStance** is cleared on `_start`'s brawl-start return (my audit of 2026-10-28). No reader is affected.
5. **PROP SMASH's pick share is below QA's band**, before and after: 2 of 60 offers on main, 2 of 59 now (3.3%; band 5
   to 30%). Its score is the lever: at 20 it is 13 of 58 (22.4%). The score is Combat's (NEEDS 1b).

## CHANGES
- **`sim/director/launch.gd`:**
  - `_biomeCands` takes `fresh` (default false), and `chooseLaunch` passes it.
  - PROP SMASH: the old line test (his height at the launch against the prop's top) is gone. Instead:
    - `_propTargets`: the props on the line ahead within `reachBh`, nearest first, one a column. A column's target is
      the prop `WorldContact._smashProp` breaks there (`WorldGround.smashIn`), with its top.
    - `_propFlight`: the body `doLaunch` and `WorldContact.toBody` make, stepped as `WorldContact.stepFighter` steps it
      (moveAir, the prop test, groundPhase; stepContact, then the test). It returns the prop broken, or -1. It reads
      only. Optional `rec` (tools only) records the path.
    - `_propOnPath`: `_smashProp`'s test on one tick's path (within `PROP_STOP` ahead, lower than the top).
  - The candidate carries `fm`, the force it was aimed with. A launch anywhere's send (`fresh`) keeps fm 1.
  - Everything is behind `biome.enabled` (off).
- **`sim/director/alchemy.gd`:** the `logOf` hoist. The dictionaries and their key order are unchanged.
- **`sim/director/exchange.gd`:** one line, `planDefStance = -1` before the brawl-start `return STARTED`.
- **`sim/director/tools/propreach_probe.gd`** (new, with its `.uid`):
  - reach and base: every launch breaks its prop and stops at it. A flight that leaves the planner's predicted path is
    counted apart, with where and why.
  - aimed: the counts and the largest force.
- **Parked:** `docs/director/pending/prop-reach/apply.cjs` (with `--check`), Combat's one line in
  `data/combat/launch_biome.json`:
  - PROP SMASH gains `"aimFm": [1.0, 1.25, 1.6, 2.0, 2.5, 3.0]` and a note;
  - the candidate row allows extra keys, so the schema is unchanged;
  - it changes `DirData.dataHash` (the replay header), not the golden.

## DECISIONS
1. **Aimed like BUILDING SMASH, with the reach test as the offer.** This is the brief's second option, built on the
   first's test.
   - The old test failed two ways that only a flight shows: the slide ends before the prop, or a crest throws him over a
     low one.
   - `WorldContact.journey`'s step is the runtime's own, so the planner now reads both cases exactly, rather than the
     generic `predictFlight`.
   - Aiming then keeps far props in reach, as BUILDING SMASH searches its arcs. In the probe, 6 of 48 plans needed more
     than the row's force (at most ×2.0).
   - The force list is data in Combat's row. Without the park, only the row's force is tried, which is the brief's
     first option: none short or over either (the probe's base line).
   - 3.0 is the long haul's cap (`HAUL_FM_MAX`).
   - Like the long haul, a launch anywhere's send is not aimed (its length is its power's).
2. **The probe tells a wrong prediction from a changed world.** It compares the real flight with the predicted path,
   skipping frozen ticks. A flight that left that path before the prop is reported on its own line, with the place and
   that tick's events. It is not counted as short or over, since those would be the planner's error. This follows World's
   own probe pattern, where short and over were reported and routed.
3. **The zip lead is closed with no change.** The price is the table's: the director's line prints it at the press.
4. **`logOf`: hoist only.** Building only the changed slots would mean keeping the entries between calls, but Controls'
   readers change the arrays and entries they are handed (`press_read.gd` 119 to 143 and 429 to 435). Sharing them is
   not safe.

## TICK NUMBERS
**Valid, re-run 2026-10-30 in the EP's quiet window** (0 to 6% CPU before and after every run, no other Godot process).
`dir_prof` (AI match, hand-made world, seed 1, 3,600 ticks), alternated, five runs each: main fbe18b14 with this work,
and the same tree with this work's lines in `launch.gd`, `alchemy.gd` and `exchange.gd` reversed. Below-normal priority.
"Twin hash same" in every run. Both trees play the same match by the call counts (388 presses, 2,493 exchange ticks).

| five runs, mean (range) | without this work | with this work |
| :--- | ---: | ---: |
| control.request, µs a call | 173.8 (170.9 to 176.8) | 155.1 (153.8 to 157.3) |
| tick mean, µs | 242.4 (240.5 to 243.4) | 239.9 (238.6 to 241.4) |
| tick p50, µs | 256 (255 to 257) | 256 (254 to 257) |
| tick p99, µs | 693 (638 to 729) | 654 (630 to 680) |

- A press is about 19 µs cheaper (11%), and the two ranges don't overlap. Over the match that's about 2 µs a tick, which
  is what the tick mean moved by. The p50 doesn't move, and the p99's ranges overlap, so that difference isn't shown.
- `biome.enabled` is off, so this doesn't measure the planner's cost with the switch on (RISKS 2).

**Superseded: the first reading, invalid because the machine was loaded** (23 to 52% CPU from other sessions' jobs, 6
other Godot processes at every run). Kept for the record. Main 782aeef4 and this tree, alternated, three each.

| run | main: tick mean / p50 / p99 (µs) | this tree | main: control.request a call | this tree |
| :--- | :--- | :--- | ---: | ---: |
| 1 (load 23%) | 270.6 / 269 / 768 | 298.4 / 283 / 896 | 191.7 | 196.2 |
| 2 (load 42%, 32%) | 256.3 / 258 / 760 | 261.0 / 265 / 748 | 184.4 | 171.9 |
| 3 (load 47%, 52%) | 261.0 / 262 / 751 | 260.6 / 261 / 753 | 188.3 | 175.1 |

- The press line (control.request, 388 presses) reads about 7% cheaper in runs 2 and 3, about 13 µs a press. Run 1 is
  slower on every line, so that run's machine was busier.
- The micro-bench (42 to 21 µs a `logOf` call, alternated, the same output) is a separate reading from before the
  re-run.

## Gates
Each gate's last line, then its exit code. Every Godot gate ran through `tools/gate.mjs` ("no SCRIPT ERROR lines").

**On 782aeef4 with my files and the park applied:**
- `npm test --prefix sim`: "all 5 stages passed", 0; `sim/core/test/golden.json` is byte-identical afterwards.
- `node tools/validate.js`: "279 files checked, 0 errors, 0 warnings", 0.
- `--self-test`: "parser 284 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 171; data cases 8182", 0.
- `node tools/lint-determinism.mjs`: "determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core,
  sim/director, sim/world, sim/input", 0.
- `node qa/run-all.js`: "all 7 test files passed", 0.
- `parity.gd`: "golden check passed", 0.
- `load_split.gd`: "ok: the director is a load of its own, and SimDir's calls are all in their scripts", 0.
- CI's net modes, each 0:
  - rollback: "PASS 3 sessions, 1800 confirmed-tick hash comparisons, 0 failure(s)"; negative control "4 break(s)
    caught, 0 missed";
  - desync: 14 runs, 0 failures; negative 5 caught;
  - spectator: 180 comparisons, 0 failures; negative 5 caught;
  - delay and transport: 0 failures; negatives 2 of 2;
  - rollback `--ai` and `--ai=sim`: "3 AI sessions … 0 failure(s)"; negatives 7 caught;
  - `--setup=depth` and `--setup=planet2`: 1800 comparisons, 0 failures; negatives 4 caught;
  - enet: 2 two-process matches, 0 failures; negative 2 of 2.
- `determinism.gd` plain and `--intro`: "determinism passed", 0 each. `seam_sweep`: "seam sweep passed", 0.
- `flash_worst` then `check-log.js`: "flash count passed: …", 0.
- Rendering's checks, each 0: after, city (every row ok), cue, depth, flash, flash register, flight, ground, hud words,
  lane, open, pane, patch, shape, sky, stage, cue `--profile=spaced`, each "… check passed".
- `split_sweep`: "split sweep passed", 0.
- `campaign_episode`: "campaign_episode: the two plays are the same to the bit (1800 ticks a stage; 3.5 s and 2.9 s)", 0.
- `anim_check`: "anim check passed", 0.
- World:
  - all 41 `sim/world/tools/*_check.gd`: "<NAME>: 0 check(s) failed" each ("CRATERS CHECK: 0 failed"; lane_check "LANES
    Bellgate: 10 avenues, buildings of row 1 or 2 across an avenue: 0"), 0;
  - `gen2_soak`: "GEN2 SOAK: 12 match(es), 0 not the same twice", 0;
  - `flighthooks_probe`: "flighthooks probe passed", 0. Its prop line: "PROP SMASH in 10 launches that reached the prop
    broke it 10 times, he stopped at it 10 times, and the prop query left it out after 10 times (0 more stopped short
    of the prop and 0 passed over its top …)".
- Encounter's, each 0: "launchbiome probe passed", "sigafter probe passed", "sigvariants check passed", "brawl cases: all
  passed", "reads_check: 16 of 16 passed".
- tick_hash, main against this tree (switch off): 43,200 lines, byte-identical.

**On 19dcd72d with the final files:**
- validate: 279 files, 0 errors, 0.
- parity: "golden check passed", 0.
- `determinism.gd`, switch off, plain and `--intro`: "determinism passed", 0 each.
- `determinism.gd`, switch on (the file's `enabled` set true for the run, then restored, cmp equal), plain and
  `--intro`: "determinism passed", 0 each.
- All 20 `sim/input/test/*_test.gd`: "<name>: N checks, 0 failed", 0 each. These include agency_input_test 105, press_read
  439, params_cache 36 and the new hold_toggle 76.
- `mash_probe`: "mash_probe: 6 checks, 0 failed", 0.
- `loader_check -- 200 1`: "loader check passed", 0.
- On the final launch.gd (the `rec` record and comments only since the gates above), each 0: `propreach_probe` "propreach
  probe passed", `flighthooks_probe` "flighthooks probe passed" (prop line as above), `launchbiome_probe` "launchbiome
  probe passed", `sigafter_probe` "sigafter probe passed".

**The probe, `propreach_probe`:**
- **reach:** "PROP SMASH in 48 launches on 12 planets broke its prop 47 times and stopped him at it 47 times; on the
  predicted path 0 ended short of the prop and 0 passed over its top; 1 left the predicted path before the prop".
- **base** (no aimFm): the same.
- **aimed:** 6 of 48 plans took more than the row's force (largest ×2.0). PROP SMASH is offered at 7,717 of 28,800 poses
  searched with aimFm, and at 7,039 without. Main's line test offered it at 7,905, a ninth of which failed.
- **main** (the first version of the probe, on 782aeef4): 48 launches: 39 broke, 7 short, 2 over.
- **examples:**
  - a lichen_rock 2,939 ahead broke at speed 368, force ×1.00;
  - a boulder 324 ahead broke at speed 1,451, force ×1.60, 8.7 damage;
  - the one that left the path: planet 2, touch 0, x 11664. He left the ground at 12,248, 1,678 short of the boulder,
    when the ground there and just ahead rose about 30 units in that tick, and passed 138 over its top.

**The launch mix, `launchbiome_batch --on`** (32 seeds × 6 gen 2 AI matches, 312 min of fight a run, below-normal priority):

| | main | this tree | this tree, PROP SMASH score 20 |
| :--- | ---: | ---: | ---: |
| launches | 505 | 510 | 509 |
| PROP SMASH taken where offered | 2 of 60 (3.3%) | 2 of 59 (3.4%) | 13 of 58 (22.4%) |
| largest share of all launches | SMASH ACROSS 31.9% | 31.4% | 30.8% |
| sea landings | 9.1% | 9.2% | 9.2% |

The other biome candidates are taken where offered as follows (this tree): TREE LINE 30.2%, CLIFFSIDE 26.5%, SKIM ASHORE
17.6%, DOWNHILL 14.3%, MARSH SWALLOW 0 of 6. No biome candidate is over 23% of launches inside a biome with 10 or more.

**The zip trace** (767ed0d, QA's overlay: `anywhere`, `answer`, `water` and `rally` on, `QA_PLANET` as QA's run):
- The record: seed 105, light zip by the RIVAL at tick 31232, ki lost 21.77, end "stopped", 0 ticks.
- Tick 31232: feed "RIVAL ZIP STRIKE | 5 bh; 20 ki; a tell of 6 ticks, then 7 in", then "RIVAL ZIP ENDS | stopped". The
  same tick has a bolt's `shot_hit` and damage 22.84 (blast), dealt to him in guard.
- The RIVAL's ki goes 33.193 → 11.424: −20 (the zip) − 1.827 (guard, 8%) + 0.058 (regeneration).

## NEEDS FROM EP
1. **Combat:**
   - (a) Apply `docs/director/pending/prop-reach/apply.cjs <tree>` (one line, PROP SMASH's `aimFm`; `--check` first).
     Without it PROP SMASH tries only its own force: still none short or over, but fewer far props are offered.
   - (b) PROP SMASH's score: 10 leaves it at 3.3% where offered, below QA's band, before and after this change. At 20 it
     is 22.4% (13 of 58), beside CLIFFSIDE's 26.5% and DOWNHILL's 14 to 20%. Combat's note already says to read it again
     before `biome.enabled` goes on. I have not changed it.
2. **QA** (`qa/godot/records.gd` around 621): a zip that ends in the tick it starts loses its printed price. `zip_end`
   closes `zopen` before the feed loop reads the "ZIP STRIKE" line, so the record falls back to the ki a tick later, and
   that includes the same tick's guard drain. Reading the feed before closing would make `zip.price` exact on every zip.
   The lead itself is closed: there is no price bug.
3. **World** (for information, no change asked of Encounter's code): the planner's prediction, like
   `WorldContact.journey`, reads the ground as it is, not as the flight changes it. In 1 of 48 probe launches, the
   ground where his skid was, and the next few columns ahead, rose about 30 units in the tick he reached it. World's structures add rubble as a building falls,
   and that tick had evacuations. His skid then left the ground off it and passed over the boulder. If World wants the
   journey to see what the flight breaks, the planner reads it with no change.

## RISKS
1. **A world changed by the flight itself.** The prediction cannot see craters, trenches or rubble the flight makes on its
   way (1 of 48 in the probe). Such a launch then plays as a plain across send past the prop.
2. **The planner's cost with the switch on.** Each launch beat with props ahead now runs up to six short journeys. Each
   stops at the break or the journey's end (World's 900-tick cap). This is only with `biome.enabled` on, at launch beats.
3. **Aimed damage.** A send aimed up to ×3 arrives faster, so the prop's bump hurts more (the boulder example: 8.7). This
   is the long haul's rule, and Combat may want a lower cap.
4. **The depth frame.** In a brawl with depth on, the plan is made in the brawl's line frame, as every launch plan is.
   The body's start differs from the world by the frame's offset, a few units.

## NEXT
- Combat's two items (aimFm, the score), then QA's batch with `biome.enabled` on.
- Rendering's broken props in the view (their brief), and biomes.md section 4.

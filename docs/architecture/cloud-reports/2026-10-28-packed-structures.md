# Cloud report: buildings and trees as packed arrays (Simulation and Engine, 2026-10-28)

Brief: `docs/ep/cloud-briefs/simulation-packed-structures.md` (NEXT 1 of the snapshot-tick report). Page: `docs/architecture/packed-structures.md`. Branch: `cloud/simulation-engine/packed-structures`.

## SUMMARY
Buildings' and trees' per-tick fields now live in packed arrays on `SimState`. The records themselves are shared by every snapshot, and a restore hook points them at the restored arrays.

- **Snapshot take:** 73% cheaper (1.71 to 0.46 ms on the hand-made world, 1.67 to 0.50 ms on planet 7).
- **Restore:** 81% cheaper (3.21 to 0.62 ms, and 3.07 to 0.67 ms).
- **What a snapshot holds:** 202 objects become 18. The payload bytes are identical, so it is the same data.
- **Hash:** the golden is byte-identical, and the state hash is identical tick by tick on 7 seeded matches (25,207 ticks, hash order unchanged).
- **Gates:** every gate passes, and every negative control still fails as it should.
- **Tick:** unchanged within noise.

## CHANGES
Mine:
- **`sim/core/state.gd`:**
  - the arrays on `SimState`: `bHp`, `bAlive`, `bFmask`, `bFdmg`, `bMarks`, `bFled`, `bPopAlive`, `bWear`, `tAlive`, `tBurn`, plus `bG` and `tG` (the generation records by index), `hold`, `bBound` and `tBound`;
  - `bindStructures(fresh)`, `bindCheck()`, `bound()`, the restore hook `afterRestore()` and `_rebuildRecords()`;
  - the `Hold` class;
  - `Building` and `TreeState`: the per-tick fields become properties that read the hold when bound and their own `_` fields when not, so `Building.new()` works as before. A generation write on a bound record updates `bG` or `tG`.
  - the SNAPSHOT rules: `SimState` shares the records' arrays and the hold, and copies `bFdmg`, `bG` and `tG` one level deep. The record classes and the generation classes are marked `shared`.
- **`sim/core/sim.gd`:** `_mEnd` binds the new match's world; `step` calls `bindCheck()`.
- **`sim/core/hash.gd`:** a bound state's per-tick fields are read from its arrays, with the same order and types. A snapshot's records are bound to the live state's hold, so this is what makes a snapshot hash as itself.
- **`docs/architecture/packed-structures.md`** (new) and this report.

Not mine (the EP's grant). These need review:
- **Netcode, `net/snapshot.gd`** (+31/−6 lines):
  - a class rule `{"shared": true}`: such a class is shared wherever it is met, like a data definition, and is left out of the generated copier (`_shareInit`, `_classes`);
  - a field rule `"shallow"`: copied with `.duplicate()`, its elements shared (`shallowOf`, `generatedSource`, `Copier.fill`);
  - `restore()` calls `S.afterRestore()`;
  - the header comment is updated.
- **World:**
  - `sim/world/brunt.gd:891-892` and `sim/world/blast.gd:161-162`: `else: b.fdmg = b.fdmg.duplicate()`. A snapshot shares the floor-damage array, so it is copied before the writes in place that follow.
  - `sim/world/epoch.gd:676`: `S.bindStructures(true)` after the swap replaces both arrays. The kept buildings and trees are bound again in place, so they stay the same objects (`epoch_check` asserts it). The plan's prepared records are copied, so a replay of the swap after a rollback finds them as prepared.

Gates on the final tree (the last line, exit code):
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings", 0
- `--self-test`: "parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8177", 0
- `node tools/lint-determinism.mjs`: "determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input", 0
- `npm test --prefix sim`: "all 4 stages passed", 0
- `parity.gd`: "golden check passed", 0. The golden is byte-identical.
- determinism, plain: "determinism passed", 0
- determinism, `--intro`: "determinism passed", 0
- all 40 `sim/world/tools/*_check.gd`: 0 each, each printing "…: 0 check(s) failed" ("CRATERS CHECK: 0 failed"; lane_check prints "… across an avenue: 0").
  - That includes `epoch_check` "EPOCH: 0 check(s) failed" and `step_check` "STEP: 0 check(s) failed".
  - The six older World checks also pass: blastcheck, blockcheck, deepencheck, directcheck, minecheck and stagecheck, 0 failed each.
- `gen2_soak.gd`: "GEN2 SOAK: 12 match(es), 0 not the same twice", 0
- `campaign_episode.gd`: "campaign_episode: the two plays are the same to the bit (1800 ticks a stage; 7.3 s and 6.4 s)", 0
- `anim_check.gd`: "anim check passed", 0
- `split_sweep.gd`: "split sweep passed", 0
- `load_split.gd`: "ok: the director is a load of its own, and SimDir's calls are all in their scripts", 0
- `rollback_check.gd`, one process per seed:
  - seeds 1, 2, 3 and 4: "PASS 9 sessions, 21600 confirmed-tick hash comparisons, 0 failure(s)", 0 each. That is 36 sessions and 86,400 comparisons in all.
  - `--setup=calm --seeds=1,2` (rollback across the calm turn): "PASS 18 sessions, 43200 confirmed-tick hash comparisons, 0 failure(s)", 0
  - `--negative-control`: "PASS negative control: 56 break(s) caught, 0 missed", 0
- `desync_check.gd`:
  - `--seeds=1,2`: "PASS 126 runs, 252 checkpoints matched, 0 failure(s)", 0
  - `--setup=planet --seeds=7,8,9 --profiles=lan,p120,far`: "PASS 63 runs, 126 checkpoints matched, 0 failure(s)", 0
  - `--negative-control --ticks=600`: "PASS negative control: 48 break(s) caught, 0 missed", 0
- `spectator_check.gd`:
  - `--seeds=1,2`: "PASS 18 spectated sessions, 1620 spectator hash comparisons, 0 failure(s)", 0
  - `--setup=planet --seeds=7 --profiles=lan,p80j,p200,far`: "PASS 4 spectated sessions, 360 …, 0 failure(s)", 0
  - `--negative-control --ticks=600`: "PASS negative control: 32 break(s) caught, 0 missed", 0
- `delay_check.gd`: "PASS 0 failure(s)", 0. Its negative control: "PASS negative control: 2 of 2 broken choosers caught", 0.
- **Hash trace** (a scratch tool, not committed): `SimHash.stateHash` after every tick on main and on the branch.
  - Seven matches of up to 3,600 ticks: AI seeds 1 and 4, the features setup, planet 7, gen 2, and two calm-turn planets.
  - The two files of 25,214 lines are byte-identical.
- **Rollback across a forced calm-turn swap** (a scratch tool): a restore 7 or 25 ticks back on every third tick, from 40 ticks before the swap to 200 after. Main and the branch give the same results.
  - 3 of 4 runs are the same as the straight run on every tick.
  - Seed 2 with 25-tick rollbacks differs at the swap tick on main too (RISKS).

**Bench.** main (a worktree of `origin/main`) and the branch ran back to back, one process at a time, on a quiet 4-core Xeon at 2.8 GHz (load 0.8 at the start). Command: `rollback_bench.gd -- --quick`, and `--planet`.

| | main | branch |
|---|---|---|
| take (pooled), hand-made: mean / p99 | 1.711 / 3.570 ms | **0.458 / 1.305 ms** |
| restore, hand-made: mean / p99 | 3.212 / 9.719 ms | **0.615 / 1.522 ms** |
| take, planet 7: mean / p99 | 1.668 / 3.289 ms | **0.500 / 1.020 ms** |
| restore, planet 7: mean / p99 | 3.073 / 5.306 ms | **0.665 / 1.197 ms** |
| snapshot at tick 0, hand-made: bytes / objects / scalars | 118,326 / 202 / 2,834 | 118,326 / 18 / 1,876 |
| p200 peer frame, save every tick: mean / p99, hand-made | 6.96 / 28.03 ms | 3.17 / 19.40 ms |
| p200: save / restore ms a frame, hand-made | 3.62 / 0.74 | 0.94 / 0.17 |
| p200 frames over budget at x4, hand-made / planet | 39.2% / 39.6% | 25.5% / 25.4% |
| tick (bots): mean / p50 / p99, hand-made | 0.807 / 0.514 / 2.226 ms | 0.636 / 0.425 / 2.156 ms |

Native tick (`tick_prof.gd`, 3,600 ticks, µs, mean / p50 / p99). The twin hash is "same" in all four runs.

| match | main | branch |
|---|---|---|
| AI match | 749 / 637 / 2532 | 712 / 625 / 2364 |
| gen 2 planet | 745 / 660 / 2416 | 740 / 652 / 2196 |

The extra read through the hold does not show in the tick: the difference is within the ±10% run-to-run spread. `SimHash.stateHash`, which is outside the loop, went from 43 to 53 ms on the hand-made world and from 50 to 34 ms on the planet, which is noise of the same kind.

## DECISIONS
- **The records are shared and their fields are properties, as before.** About 500 lines outside `sim/world/` read `b.hp` and its like, and none of them changed. An unbound record keeps its fields itself, so tools that make a `Building.new()` behave as before.
- **One `Hold` per binding, not a reference to `S`.** A building that pointed at its state would make a cycle (S → buildings → building → S), and every state would leak. The hold holds only arrays. Since restore writes into the same `S`, the hook re-points one hold: it does not walk the buildings.
- **The calm turn binds its kept records again in place.** `epoch_check` asserts they stay the same objects. The old hold is marked `moved`, so restoring a snapshot from before the turn binds them back. That walk happens only then.
- **`bFdmg`, `bG` and `tG` are copied one level deep.** Their elements are copy-on-write: the generation records are sealed, and a floor-damage array is copied before a write in place, in the two World lines. A deep copy of 118 small arrays a take would have cost most of the gain.
- **A generation write is caught by comparing references, not by a counter.** My first version stamped writes with a process-wide counter. The desync field walk then flagged the counter as a difference between two agreeing peers (105 false failures), so I removed it. The hook now compares the restored `bG` and `tG` with the hold's (an engine compare), and nothing per-process is in the state.
- **The hash reads the arrays.** A snapshot's records read the live state, so `SimHash` of a snapshot root (rollback_check hashes them) must read the root's arrays. The order and types are unchanged.

## NEEDS FROM EP
1. **Netcode: review the `net/snapshot.gd` lines** (CHANGES): the `shared` class rule, the `shallow` field rule and the restore hook call.
   - The desync report now names a building's difference `S.bHp[i]` (it was `S.buildings[i].hp`). The checks do not assert the name.
2. **World: review the five lines** in `brunt.gd`, `blast.gd` and `epoch.gd` (CHANGES). Two contracts to note:
   - a `fdmg` array is written in place only in the tick that made it, or after copying it;
   - `S.buildings` and `S.trees` are replaced whole during play, never changed in place.
3. **World and Netcode: a pre-existing rollback hazard across the calm turn**, reproduced identically on main.
   - Planet 7, seed 2, turn decided at tick 30, swap at 66: restoring 25 ticks back on every third tick makes the state differ from the straight run at the swap tick. 7-tick rollbacks and seed 1 are clean, and so is `rollback_check --setup=calm`.
   - It points at the swap's process-level caches (`WorldEpoch._plans` and `_jobs`): a rollback past the preparation's start replays against a cache already moved on.
   - My change neither causes nor fixes it, but it decides whether online play can roll back across a turn.

## RISKS
- **A snapshot's records read the live state.** Anything other than `SimHash` that reads `root.buildings[i].hp` from a snapshot gets the live value. Today only `rollback_check` and `spectator_check` read roots, both through `SimHash`. `NetDesync.digest` reads live states only. The page says so.
- **The two in-place contracts** (`fdmg`, and the buildings and trees arrays) are new ways to desync rollback without failing outside it. `rollback_check` and `desync_check` would catch a breach in their profiles.
- **A snapshot restored into another state** gets records of its own (`_rebuildRecords`). No caller does this today, and the path is not exercised by a check.
- **`bindCheck` binds a tool's appended buildings by copying records that are already bound.** A tool holding a reference across a step to a record it appended after a match started would keep the old one. No check does this; all World checks pass.

## NEXT
1. **Encounter's tick-accessor patch** (the snapshot-tick report's NEEDS 2), then its structural pass on the director's tick. The snapshot is now 0.46 ms, and the tick (0.6 to 0.8 ms, about 80% director) is the larger cost per frame.
2. **The calm turn's rollback hazard** (NEEDS 3), with World and Netcode: either move the swap's preparation into the state, or key its caches so that a replay re-derives them.
3. **Fighters as the next copy cost.** With buildings and trees gone, the take is mostly the fighters' objects and the terrain arrays. Re-measure with `measure()` before going further.

Look: nothing a player sees changed.

## Follow-up (local, 2026-10-28)
The EP's gate on HEAD df121d4e found Netcode's `transport_check` (2afeda13, after this branch started) failing at ticks 366 to 374. The first RISK above was wrong: `NetDesync.digest` does read a snapshot, since `NetSession.onConfirmed` hands over a snapshot's root for a tick behind the present, and it read the records, so the live state's buildings. The digest now reads the arrays when `S.bound()`, as `SimHash` does (Netcode's `net/desync.gd`). A new check, `sim/core/tools/two_states_check.gd`, runs three states in one process with rollbacks, snapshots read late and a restore into another state. The page has both (`../packed-structures.md`).

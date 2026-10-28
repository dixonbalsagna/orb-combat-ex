# Cloud report: a cheaper snapshot and a cheaper tick (Simulation and Engine, 2026-10-28)

Brief: `docs/ep/cloud-briefs/simulation-snapshot-tick.md`. Page: `docs/architecture/snapshot-tick.md`. Branch: `cloud/simulation-engine/snapshot-tick`.

## SUMMARY
The per-match constants (a building's 17 generation fields, a tree's x and h, `S.bIdx`, `S.base`) are now shared by every snapshot instead of copied. The results:
- the snapshot's payload is 23% smaller;
- its scalars are 43% fewer;
- a pooled take costs 14% less on the hand-made world and 25% less on a planet;
- a restore costs 0 to 9% less.

The golden is byte-identical and every gate passes.

The cut is not half. A building or tree still costs the copier about 5 µs of bookkeeping as an object, whatever its fields. Halving needs fewer objects, which is the next step (NEXT 1).

The tick's top items are not in the core. About 80% of the tick is the director and its AI (Encounter's `sim/director/`). My files got a bit-identical `pow` cache, which pays for the new field reads, so the branch's tick is unchanged within noise. A bit-identical patch for Encounter's accessors is staged, not applied. It cuts the AI match's p50 by about 15% (819 to 694 µs). 0.3 ms needs the director's own redesign.

## CHANGES
Mine:
- `sim/core/state.gd`:
  - `Building` and `TreeState` keep their mutable fields and get `g`, a `BuildingGen` or `TreeGen` holding the generation fields;
  - the old names are properties that read `g` and write through it, copy-on-write once sealed;
  - `SNAPSHOT` rules on `SimState`, `Building` and `TreeState`;
  - `SimState.sealFresh()`.
- `sim/core/sim.gd`: `step` calls `_step` and then seals the tick's new records. Each `MatchJob` piece seals too.
- `sim/core/detmath.gd`: `pow` keeps its last 16 answers (a pure function, so the same doubles come back).
- `sim/core/tools/tick_prof.gd` (new): the tick part by part, with a twin proving the timed step is the step.
- `docs/architecture/snapshot-tick.md` (new).
- `docs/architecture/pending/tick-accessors/apply-tick-accessors.cjs` (new, parked) and the pending `README.md` line.

Not mine:
- **Netcode's `net/snapshot.gd` (+35 lines, not in the brief's grant; please confirm).** The brief's "so the copier can share that reference" needs it. The copier now reads a class's `SNAPSHOT` constant:
  - it assigns a `share` field instead of copying it;
  - it drops a `skip` field (the building's forwarding properties) from `props()`, so neither the generated copier nor the reflective copier touches it;
  - `measure()` and `aliasAudit()` leave both kinds out.
- **World's lines: none.** Every generation write and the calm turn's renumbering (`epoch.gd:661`, `structures.gd:255`) work unchanged through the write-through properties, so I used no line of the grant.

Gates (the last line, exit code):
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings", 0
- `--self-test`: "parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8153", 0
- `node tools/lint-determinism.mjs`: "determinism lint ok", 0
- `npm test --prefix sim`: "all 4 stages passed", 0
- `parity.gd`: "golden check passed", 0, so the golden is byte-identical. The scratch copy with the parked director patch also gives "golden check passed", 0.
- determinism (`render/tools/determinism.gd`), plain and `--intro`: "determinism passed", 0 each
- `anim_check.gd`: "anim check passed", 0
- all 40 `sim/world/tools/*_check.gd`: 0 each, and 39 print "0 check(s) failed" or their pass line.
  - `step_check` prints "STEP: 3 check(s) failed" with exit 0.
  - All three are wall-clock budget lines ("no call of the job is long: the longest 97 ms"), measured while other gates ran.
  - main, in a copy on this machine, gives 2 of the same with exit 0. Not this change.
- `split_sweep.gd`: "split sweep passed", 0
- `campaign_episode.gd`: "the two plays are the same to the bit", 0
- `load_split.gd`: "ok: the director is a load of its own", 0
- `rollback_check.gd --negative-control`: "PASS negative control: 56 break(s) caught, 0 missed", 0
- `rollback_check.gd` (default profiles): "PASS 36 sessions, 86400 confirmed-tick hash comparisons, 0 failure(s)", 0
- `tick_prof.gd`: the twin hash is "same" in all 6 runs (main, branch and the director patch, each on an AI match and on gen 2).

Bench (`net/tools/rollback_bench.gd -- --quick`). main and the branch ran one after the other on a quiet 4-core Xeon at 2.8 GHz. This machine is about 1.4x slower than the EP's.

| | main | branch |
|---|---|---|
| take (pooled), hand-made world: mean / p99 | 2.231 / 4.009 ms | 1.922 / 3.395 ms |
| restore, hand-made world: mean / p99 | 3.595 / 6.500 ms | 3.589 / 6.617 ms |
| take, planet 7: mean / p99 | 2.094 / 3.731 ms | 1.581 / 2.989 ms |
| restore, planet 7: mean | 3.306 ms | 3.022 ms |
| bytes, hand-made world: tick 0 / tick 1799 | 154,395 / 159,243 | 118,326 / 123,174 |
| bytes, planet 7: tick 0 | 160,726 | 123,703 |
| scalars, hand-made world: tick 0 | 4,972 | 2,834 |
| scalars, planet 7: tick 0 | 5,076 | 2,815 |
| save per frame at p200, saving every tick: hand-made / planet | 4.51 / 4.08 ms | 4.02 / 3.50 ms |
| tick, bots: mean / p50 / p99, hand-made world | 0.819 / 0.632 / 2.164 ms | 0.819 / 0.592 / 2.280 ms |
| tick, bots: mean / p50 / p99, planet 7 | 0.910 / 0.684 / 2.995 ms | 0.839 / 0.621 / 2.384 ms |

Native tick profile (`tick_prof.gd`, 3,600 ticks, in µs, mean / p50 / p99):

| match | main | branch | branch + parked director patch |
|---|---|---|---|
| AI match | 859 / 819 / 2462 | 898 / 814 / 2774 | 758 / 694 / 2313 |
| gen 2 planet | 874 / 826 / 2680 | 903 / 814 / 2996 | 827 / 730 / 2576 |

Each mean holds a first tick of about 200 ms, which is the director's scripts compiling on first use (the load split) and adds about 55 µs to a 3,600-tick mean. The p99s move by ±10% between runs.

## DECISIONS
- **The constants moved behind properties, not renames.** About 500 lines outside `sim/world/` read `b.x` and its like (Rendering 466, UI, Audio, the director, the tools). A property keeps all of them, and the snapshot's sharing works the same. A read costs about 0.15 µs more. On the tick that is 1 to 2%, paid back by the `pow` cache.
- **Copy-on-write records, sealed at the end of each tick and match piece.** The calm turn rewrites districts and indices mid-match, so "per-match" really means "per world". A write to a sealed record copies it first. So no snapshot's record ever changes, and no World line had to change.
- **`S.base` and `S.bIdx` stay plain fields, shared by contract.** Each is built whole and only ever replaced whole. Godot's packed arrays are shared references (I checked), so the contract is written in `state.gd` and `rollback_check` would catch a breach. Every in-place write today is to a world under construction.
- **The director patch is parked, not applied.** The tick's top items are Encounter's (and Controls' `input_data.t`), and the brief grants no lines there. The patch is ten anchored, idempotent edits:
  - caches keyed by the data object or forced profile they were read from (tools edit those blocks in place, so the cached block is the same object);
  - size checks before the dirI sizing chains.

## NEEDS FROM EP
1. **Netcode: confirm the `net/snapshot.gd` lines** (the `SNAPSHOT` rule: share and skip), or take them as theirs.
2. **Encounter: a grant for `docs/architecture/pending/tick-accessors/`** (run `node docs/architecture/pending/tick-accessors/apply-tick-accessors.cjs .`). It touches `alchemy`, `brawl`, `data`, `grapple`, `interrupt`, `rally` and `zip.gd`. The golden stays byte-identical, and calls drop from 845 to 625 a tick.
3. **Encounter: the tick toward 0.3 ms is their design call.** After the patch, the largest items are `DirBrawl.tick` and its twenty sub-ticks, `DirBrawl.aiInput` and `_move`, and `DirAI.aiInput`. A director that skips the sub-ticks with nothing to do would be the next large cut.
4. **Netcode and World: the next snapshot step (NEXT 1)** needs both.

## RISKS
- **A write in place to `S.base` or a `bIdx` bucket during play would now desync rollback** (it would be silent outside rollback). The contract is in `state.gd`, and `rollback_check` catches it.
- **The record properties cost Rendering about 0.15 µs per read.** The view reads perhaps 1,000 a frame, about 0.15 ms natively. It was not measured on a phone, and Performance should glance at it.
- **`SimState._fresh` is a static list.** A tool that makes buildings and never steps or starts a match holds those records until the next seal. That is harmless: values never change.
- **`step_check`'s timing lines fail on this machine on main too.** They are budget assertions, not results.

## NEXT
1. **Buildings and trees as shared objects.** Their per-tick fields would become packed arrays on `SimState` (hp, alive, fmask, fdmg, marks, fled, popAlive, wear; alive, burn), with a restore hook that points the shared objects at the restored arrays. Buildings and trees are 80% of the take today (1.37 ms and 0.43 ms of 2.16), so the take should fall to about 0.5 ms. This needs World and Netcode.
2. **After NEEDS 2, Encounter's structural pass on the director's tick.** Then re-bench with `tick_prof.gd` and `rollback_bench.gd`.

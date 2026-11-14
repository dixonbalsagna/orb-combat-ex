# Park: terrain step 2, no shafts and water where it could come from (World, 2026-11-09; RE-CUT 2026-11-13 for Camera's chase_rush_check)

**Re-cut, 2026-11-13 (A1 brief item 3).** Camera's `chase_rush_check` failed 4 of 130 rows with the park (jolt 0.153, 0.138, 0.137, 0.153 at the tick-96 split; limit 0.10). Bisected on HEAD def3445a with the park applied, one change at a time: **the groove settling is the cause** (trenches stored widened and shallowed to the angle of repose). With the whole park but `globe.settle` false: 130 pass. With the crater settling on and the groove settling off: 130 pass. The cliff form, the shaft cap, the floor and ceiling are not the cause. A trench the knockback slide cuts at the send's landing is 121 to 152 deep and 64 across; stored settled it is 56 to 63 deep and 69 to 77 wide, so the ground the landing body slides on is about 65 units higher and the fight, the swing and the camera's split go differently. Widening only (the floor kept at 121 deep) failed too (jolt 0.101 to 0.118 at tick 110), so it is the trench ground, not the amount. **The re-cut ships the groove settling OFF** (`craters.json globe.settleGrooves` false, new): `chase_rush_check` 130 pass again, parity passes, `GLOBE` 0 failed. The cost: the audit's steps. With the groove settling off, 14 of 40 matches are over 6 steps over one body height (607 in all, worst 152, every one a slide trench: a 121-deep wall over 64 units); with it on, 0 of 40. So the "0 to 6 steps" measure is met only with `settleGrooves` true, and that needs Camera to judge the four rows (they are the same chase with a shallower, wider landing trench: the jolt is the camera splitting harder at the landing, not a wrong picture) or step 3, which sets trench widths 109 to 242 by force and where Camera re-tunes in the same window. Flip: one boolean.

EP brief of 2026-11-09 (terrain-globe-plan.md step 2). Cut on HEAD 20713b02 (`git apply --check` clean on the working tree for all three patches; the re-cut diff re-checked on def3445a). Design and numbers: `docs/world/globe-step2.md`. Runs: `docs/world/runs/globe-step2/`. Nothing is on main; nothing here is applied.

| File | What |
| :--- | :--- |
| `globe-step2.diff` | World's: `sim/world/{store,crater,craters,fill,field}.gd`, new `globe.gd` (`WorldGlobe`), `tools/globe_check.gd` (`GLOBE`, in CI), `tools/globe_audit.gd` (the ported terrain audit, a soak, left out of CI with its reason), `data/biomes/{craters,water}.json` with their two schemas (optional blocks, so the fixtures hold), the `world-checks.json` lines (after `bystanders_check`; `globe_audit` under leaveOut) and the three `.uid` files |
| `grant-simulation-field.patch` | Simulation's `sim/core/field.gd`, `nativeDepth`: two hunks (below) |
| `grant-tools-lint.patch` | Tools' `tools/lint-determinism.mjs` and its self-test: the lint learns `pow`, `exp`, `log` and `Vector3` |

**Apply order:** the lint patch first (the brief: the lint learns first; the tree is clean under the new rules), then `globe-step2.diff`, then the field grant. The golden does not move (below), so there is no separate golden patch.

## Against the brief's measures

| Measure | Result | Where |
| :--- | :--- | :--- |
| The lint learns `pow`, `exp`, `log`, `Vector3` first | Four rules; self-test 91 checks (found: bare calls, `Vector3` in a signature; not found: `SimDetMath.pow`, `.pow`, `Vector3i`, `func pow(`, strings, comments, `DirAlchemy.log(`); the sim tree is clean under them | `runs/globe-step2/lint-determinism.txt` |
| 20 hits on one spot never deeper than 0.26 R | Repeats off: 1 crater, 19 refused, centre 78.3 deep of 92.6 allowed; repeats on: 3 craters, 17 refused, 122.4 of 144.6. Negative control (shaft cap blind to relief): 915 and 893 deep | `globe-check-passes.txt`, `NEGATIVE-CONTROL-1` |
| 10 base hits stay under 560 | Radii 356, 445, 556.25 (1.25 each, a max never a sum), then refused; largest 556.2. Repeats off: largest 356 | same |
| 0 to 6 steps over 1 body height a match, 40 seeds | **Met only with `globe.settleGrooves` true** (0 of 40 matches over 6, 0 steps in all). **As shipped (off): 14 of 40 matches over 6 (607 steps, worst 152), every one a slide trench**; craters alone make none. (First cut, before the cliff fix and the trench settling: 637 steps, 12 matches over 6, worst 134.) The audit counts steps of over 75 between neighbours 32 apart, along 8 bearings out from every live record, deduped to 16-unit cells (planets 7, 12, 3, 13, 17; 3,600 ticks). The deepest crater's relief just after its dig is at most 0.324 R (the cap is 0.26 R of depth plus relief, and the new apron raises the ring by up to 0.4 of the depth) | `globe-audit-40-seeds-grooves-off-as-shipped.txt`, `-grooves-on.txt` |
| No sourceless water; a coastal trench fills along its length | Inland crater (132 deep, floor under the old sea line): dry with the switch on; **with it off it reads as sea 46.8 deep, which is the inland sea in play today**. A crater at a coast holds the sea's level; a trench cut on from the coast carries level 0.0 on all three pieces, 250 deep target settled to 80 deep. A hole under `minDug` looks for none. Negative control (every hole finds a source): 3 FAIL | `globe-check-passes.txt`, `NEGATIVE-CONTROL-3` |
| The two-peer ground check passes | Peer A reads 241 columns round the blows at both levels between every blow (so the memos are warm), peer B is snapshotted, goes on, rolls back and replays, a third state is cold: all 4,800 columns equal on all three, store hash equal. The blows include two repeats that supersede. `memo_check` (0 stale across 96 record cases and two fights) and `field_static_check` pass on the stack | same, `gates.log` |
| B1 water behind its switch | `water.json flood.enabled` false. Off: no record holds water, `nativeDepth` as it was | same |
| Changes the hash; golden in its own window | The store's slots are folded (a record is 16 numbers in the hash now, not 12), so a **gen 3 state with marks hashes differently**. The golden does not move: `parity.gd` passes unchanged (9 matches, 174,798 ticks identical; planet worlds identical): no golden recipe digs on a gen 3 planet. No golden patch. Netcode: a replay or LAN save from a gen 3 match with marks, made before this lands, will not replay after it | `parity-passes-golden-unmoved.txt` |

## Gates

| Gate | Result |
| :--- | :--- |
| World checks, `--run` (86, the re-cut tree on HEAD def3445a, one Godot at a time, below-normal) | 85 pass; `step_check` failed once on a timing line (the plates job's longest step 42.2 ms, run beside two other Godot jobs) and passes alone, 0 failed (`checks-verdicts.txt`); `--verify` ok |
| `GLOBE` | 67 ok, 0 fail; four mutation controls fail as meant: shaft cap blind to relief 6, groove takes the lower over a rim 1, every hole finds a source 3, a superseded record is read 2 |
| parity | passes on the re-cut, golden unmoved (above) |
| `chase_rush_check` (Camera's, 130 rows) | **130 pass** with the re-cut (HEAD alone 130 pass; the first cut 4 fail) |
| validate | 321 files, 0 errors; self-test 10,093 of 10,093 |
| two-fighter ratchet | 365 of 365 |
| content screen | 0 failing hits |
| Sim, render and net gates (19, one at a time on the re-cut tree, below-normal; `gates.log`) | all pass: two_states, replay_xproc, fork, memo, rec, field_static, frame (204 checks), power, cross, load_split, places, rollback (field setup, and fights2 over three profiles), desync, determinism, seam_sweep, sweep_check, props_check, cover_water, lake_water. Their own negative controls were not re-run (their code did not change). The look gate and both flash modes are not run: nothing a player sees changes with the shipped data |

## Switches, and what each changes with the shipped data

| Switch | Shipped | With it off |
| :--- | :--- | :--- |
| `craters.json globe.repeats` | 0 | each blow digs its own crater, held by the shaft cap (a spot dented enough takes no more) |
| `craters.json globe.furrow` | false | a glancing blow digs no trench behind it (on: one `TRENCH` record, a third of the bowl's depth, a column wide) |
| `craters.json globe.settle` | true | bowls are stored as asked |
| `craters.json globe.settleGrooves` | false | trenches and scars are stored as asked (on: widened to the angle of repose; `chase_rush_check` moves with it) |
| `water.json flood.enabled` | false | holes hold no water; the sea derivation from the ground including the store stays, so a deep inland hole reads as sea |

Changes that are on with the shipped data and move a result only where it matters: the shaft cap reads the store (it was reading the old strip's two columns, which a globe match never writes, so it never saw a bowl: only a repeated spot changes); the store's ground is held between -2,080 and +960; a groove (trench, scar, scorch) crossing a rim, apron or heap cuts down from there (`sum + groove`) instead of replacing it with the lower of the two (the old form left a cliff as high as the rim at the groove's edge: with the trench settling alone, one match still had 62 steps over 1 body height, all of this kind); a blow never repeats a crater bigger than it can dig.

## Decisions I made (reverse any)

1. **Repeats ship off.** The newest-bowls list in Rendering (`tile_ground.gd:263-267`) opens each new bowl from nothing on top of tile ground that already holds the old one: with a record that supersedes, the player would see the depth jump (old + opening new) and pop back at the hand-over. Rendering's line must subtract the superseded bowl (or skip it) first; then `globe.repeats` 2 is the flip. `ground_field.gd:533` pairs craters with records by time and radius and needs the same look.
2. **Flood ships off, and it does two things.** A source search on the planet store (sea, lake, table), and the sea derivation in `nativeDepth` reading the field's ground and not the store's. Both only with the switch on. The lowest level found wins (the plan said highest: it put a hilltop lake's level into a hole beside the sea). No front in the sim: the pool is there when the hole is; the run-in is a view cue (step 4).
3. **The groove-over-rim form is in step 2** and on. **The trench settling is built and OFF** (re-cut): the 0 to 6 steps cannot be met without it, and it moves Camera's `chase_rush_check` (see the top).
4. **SCAR, HEAP and MERGE are fixed in code (kinds, slots, readers, adders) with no producer.** Nothing writes one until steps 3, 5, 6. Simulation's `_reachOf`, `_clearColumns`' segment test and `_riseAdd` need those kinds when their producers land: not in this grant.
5. The furrow is built behind a switch that stays off: it adds a record per glancing impact and a look I have not seen.

## NEEDS FROM EP

- **Tools:** `grant-tools-lint.patch` (their `tools/lint-determinism.mjs` and self-test), and the two `tools/schemas/biomes-*.schema.json` hunks in `globe-step2.diff` (optional blocks), and the `tools/world-checks.json` hunk.
- **Simulation:** `grant-simulation-field.patch`: `SimField.nativeDepth` (1) the guard `S.fieldRecs.is_empty() and not WorldFill.floodOn()` so a world with no lake still reads the flood, (2) with the flood on and a store, the sea test reads the ground less the store's delta. Both are no-ops with the switch off. Confirm the golden stays put on their side (parity passes here).
- **Rendering**, before anyone flips `globe.repeats`: subtract or skip the superseded bowl in `tile_ground.gd:263-267` and `ground_field.gd:533`. Before anyone flips `flood.enabled`: does a view read `nativeDepth` or `S.water` for the pool (I have not looked at the water sheet); the ground a pool stands on is the same store the tile bake already reads.
- **Orb or the EP:** when to flip (a) `flood.enabled` (removes the inland sea; the one behaviour change a player could notice, so a look gate with a coast crater and an inland crater) and (b) `repeats` 2.
- **Netcode:** the replay and LAN-save caveat above.

## RISKS

- The inland sea exists on main today for any deep hole (nativeDepth derives sea from ground including the store). It is only removed with the flood switch.
- With the groove settling off, a slide trench stays a 121-deep wall over 64 units (14 of 40 audit matches over 6 steps). Nothing draws trenches yet, so no picture shows it; step 4 draws them and step 3 widens them by force.
- The settling reads the store's marks only, not the base field's slope: a bowl on a natural cliff is not settled.
- Cost is not timed (the machine was shared; a timing would be void). By count: a dig on the planet store reads the ground about 9 times for the relief and 80 for the settling; with flood on, 33 field reads and a box scan on top, once, only for holes 6 or more deep.
- 40 seeds is the audit's size; QA's own band is not run.

## NEXT

Land order above, then step 3 (trenches at every power) on this record list: `addTrench` already takes `lip` and `water`, and `addScar` exists.

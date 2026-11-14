# Park: gen3-field (World, 2026-10-31 to 11-01)

Planet generation 3, the field: `planetGen: 3`, off byte-identical for gens 1 and 2 (fifteen stacked diffs; the whole stack applies on a fresh HEAD and equals the tested trees). Design, API, numbers and the answers to Rendering: `docs/world/gen3-field.md`. Built on HEAD b54dd326; **the whole stack applies cleanly on HEAD 5c2dd0de** (`git apply`, no autocrlf, checked on a fresh export, and the result equals the tested tree). **Apply in order.**

| # | File | What |
| ---: | :--- | :--- |
| 1 | `01-field.diff` | `WorldField` (cube-sphere nodes at 128, nested 512 bake, on-demand reads), the gen 3 ring read, the bake as a `SimPlanetLoad` phase, `field.json` + schema + map row + **three invalid fixture cases** (Tools' coverage rule), `field_check` |
| 2 | `02-trees-by-cell.diff` | Trees keyed by planet cell and a planet seed (match start and the calm turn's new ring); `field_load_check` |
| 3 | `03-records-store.diff` | Records (exact 32 u reads in creased cells, no cracks), the contract wrappers, `refinedByCorners`/`refined`/`shore`, the diagonal rule, `WorldStore` (craters at planet points on `S.store`), platform records and `applyRecords`; two more fixture cases |
| 4 | `04-plans.diff` | Towns and cities by plan (`sim/world/plan.gd`, `field.json plans`): the same buildings at fixed planet points, turned to the ring, bands snapped onto the lanes; `WorldSettle.assignPeople` taken out of `generate` unchanged; `settle` returns each building's `dir`; `gen` fills `S.bDir` |
| 5 | `05-landmarks-rl214.diff` | `bell_tower` renamed `clock_tower` (key only), `hill_chapel` carries `noTarget`, `WorldSettle.noTarget(index)`; schema line; the fixture's key |
| 6 | `06-craters-to-store.diff` | `WorldCrater._dig` records every gen 3 crater in the store at its planet point; with `S.frame` on the state the strip's `S.deform` write stops (no double count); `field_crater_check` |
| 7 | `07-water-records.diff` | Lakes and rivers as planet records (`sim/world/waterrec.gd`): lakes flooded in 2D from the ring's plan, river segments from the drainage (behind `rivers.json`); `applyRecords` cuts channels, `recordWater` reads the water; `field_water_check` |
| 8 | `08-bake-cache.diff` | The bake cache (`sim/world/field_cache.gd`, `field.json cache`): whole key, checksum, witnesses, rebuilt hash; a hit copied and hashed in slices; the bake hash folded in as nodes arrive; `field_cache_check`; `field_load_check` covers a warm load |
| 9 | `09-planet-and-pool-cache.diff` | The made planet in the cache (`planet_cache.gd`, `CODE_REV` and `planet_cache_vectors.json`), the node pool (`field_pool.gd`), blob helpers in `field_cache.gd`; `planet_cache_check`; a fully warm load reads nothing from the planet's function (`field_load_check`) |
| 10 | `10-node-fresh.diff` | `WorldField.nodeFresh(P, face, i, j)`: a node read fresh from the planet's function, ignoring every held, baked, pooled or cached node (Simulation's match-key sample); `field_cache_check` holds it against the cache and against a corrupted held node |
| 11 | `11-pads-and-staged-load.diff` | A building's pad (`WorldField.padRecords`, weighted-mean composition, blend kept out of neighbours' footprints) and the cache hit staged finer (checksum in chunks, witnesses, copy and hash in slices); `field_pad_check`; the record index follows a growing array |
| 12 | `12-crack-records.diff` | Cracks as planet records (store layout now `[kind, 15 numbers]`, 16 a record, cap 16,384): `addCrack`, `crackAt`, `layCracks`; the slide's paved path is recorded in `_carveSegment`; `field_crack_check`; the crater check follows the layout |
| 13 | `13-scorch-records.diff` | Scorch (beam samples: burn and never-summed groove, deduped against the last eight records): `addScorch`, `scorchAt`, `layScorch`; `field_scorch_check` |
| 14 | `14-trench-records.diff` | A slide's trench: `addTrench`, `trenchAt`; the ground is the lower of the craters' sum and the deepest groove; `field_trench_check` |
| 15 | `15-lots-and-laid-pose.diff` | `dir` of a plan building is its LAID point (after the lane snap; `pdir` keeps the plan's); lots (Art's rule: one flat per street block, footprints + sidewalk, lone buildings flagged) replace the per-building pads; `field_lot_check` replaces `field_pad_check` |
| 16 | `16-script-error-fixes.diff` | `applyRecords` and `recordWater` take the planet (the lots called them before `S.planetRing.seed` was set: 41 script errors in `field_water_check`); the scorch and trench checks use a real `SimField.begin` frame (their stand-in object gave 866 and 254 errors against Simulation's frame code); the crater check's frame helper follows the 16-number layout |
| - | `grant-simulation-framecheck.patch` | **Simulation's** `sim/core/tools/frame_check.gd`: it reads the second store record at fixed indices 11 and 12 (the old 11-number layout); with the kind-first 16-number layout (diff 12) they are `STRIDE + 1` and `STRIDE + 2`. Land with diff 12 |
| - | `grant-simulation-state.patch` | **Simulation's file** `sim/core/state.gd`: the fields `store`, `storeN`, `storeHash`, `fieldRecs`, `bDir`, `frame` the stack reads (`"store" in S` guards every use, so the stack runs without them and the store fills only when they exist). Simulation may supply its own |
| - | `grant-rendering.patch` | **Rendering's** files: `render/core/ground_field.gd` (`gen2_ring` tests `== 2`; `>= 2`) and `render/core/shapes.gd` (`bell_tower` to `clock_tower`, the other half of diff 5) |

## Gates (scratch copies of HEAD, one Godot at a time per chain, below-normal priority)

| | State |
| :--- | :--- |
| Parks 1 (diff 1) | **all pass**: 54 World checks, lint, `world-checks --verify`, validate and self-test (9825 of 9825), determinism both modes, **parity "golden check passed"**, gen 2 soak **identical to base**, two_states plain and turn, run-all 5 of 5, the audio and render gates. `step_check` failed once under load (a 25.7 ms call against a 5 ms budget) and passed 0 failed on re-run, base the same |
| Parks 1+2 (diffs 1 to 2) | **all pass**, the same list: 54 World checks, parity golden, soak identical to base, two_states plain and turn, run-all 5 of 5 |
| Diffs 7 and 8 (water records, bake cache; tree p98) | **pass**, a reduced list (the same plus `field_cache_check`, `step_check` and the UI `load_check`): lint, validate and self-test 9825 of 9825, `world-checks --verify` (60 checks), store, field, load, records, plan, crater and water checks, planet_world, lakes, rivers, ground, props and epoch checks, parity golden, gen 2 soak identical to base, determinism. The full 59-check World list and the render gates were not repeated for it (the change sits behind gen 3 guards; parity and the soak are the identity evidence) |
| Diff 9 (made planet and node pool in the cache, tree p99) | **pass**, the same reduced list plus `planet_cache_check` (and `field_load_check` with a fully warm load that reads nothing from the planet's function): 62 checks registered, validate and self-test 9825 of 9825, lint, parity golden, gen 2 soak identical to base, determinism, `step_check`, UI `load_check` |
| Diffs 10 and 11 (node fresh; pads and staged load, tree p101) | **pass**, the reduced list: 63 checks registered, validate and self-test 9825 of 9825, lint, the gen 3 checks including `field_pad_check` and the staged `field_cache_check`, planet_world, lakes, rivers, ground, props, epoch, `step_check`, UI `load_check`, parity golden, gen 2 soak identical to base, determinism |
| Diffs 12 to 15 (cracks, scorch, trench; lots and the laid pose; trees p104 and p105) | **pass**, the reduced list on both: validate and self-test 9825 of 9825, lint, `world-checks --verify` (66), the store, field, plan, crater, crack, scorch, trench, pad or lot, cache, load, water checks, planet_world, lakes, rivers, ground, props, epoch, `step_check`, UI `load_check`, parity golden, gen 2 soak identical to base, determinism |
| **Diffs 08 to 15 on landed main (59e671ed)** (tree m15b; 14 and 15 re-cut: 14 for `crater.gd`'s `baseAt` line, 15 deleting the old `field_pad_check`) | **pass**: `world-checks --verify` (66), validate and self-test 9862 of 9862, lint, the gen 3 checks, planet_world, lakes, rivers, ground, props, epoch, `step_check`, UI `load_check`, parity golden, gen 2 soak **identical to pristine main**, determinism, and Simulation's `frame_check` (with the framecheck grant: it fails on the fixed record index without it) |
| **Script errors counted** (tree m16, main + 08 to 16): every output of the gate chain is counted for SCRIPT ERROR and ERROR lines (less Godot's exit notes and the refusal `field_load_check` provokes on purpose): **0 in all**; all checks 0 failed, `frame_check` rc 0, gen 2 soak identical to pristine main, parity golden, determinism |
| Not run, by rule | render gates `outline` and `cull` (they need a window; Godot runs here are headless only). They fail the same way on any tree |
| Diffs 1 to 6 (tree p97, the whole stack) | **pass**: 59 World checks (all clean), lint, `world-checks --verify`, validate and self-test 9825 of 9825, determinism both modes, parity "golden check passed", gen 2 soak **identical to base**, two_states plain and turn, run-all 5 of 5, the audio gates. Diffs 1 to 5 (tree p96) had the same results |
| Three gates that flickered or need another owner | `shape_check` fails with diff 5 alone: Rendering's `shapes.gd` has no treatment for `clock_tower` (their half of the rename; **`grant-rendering.patch` now carries it and the check passes with it**). `warm_async_check` (audio, a yield-length timing: 87.9 and 33.9 ms against a 25 ms budget under load) and `step_check` (a call-length timing, 25 to 35 ms against 5) failed in the loaded chains and **pass on a quiet re-run** (0 failed), base included |
| Individual checks, on the final tree | `field_check`, `field_load_check`, `field_records_check`, `store_check`, `field_plan_check`, `field_crater_check`: pass |
| Parity on the landmark rename (diffs 1 to 5) | "golden check passed": the rename moves no golden key |

## Names Simulation asked for (as built)

- Reads, pure at a unit direction: `WorldField.height(P, x, y, z)`, `biome`, `fine`, `heightBake`, `biomeBake`, `nodeH(P, face, i, j)`, `dirOf(face, i, j, n)`, `dataHash()`; the lower level is `sample(F, qx, qy, qz, step)` (sets `F.oh`, `F.ob`, `F.ofine`).
- Store on the state: `S.store` (11 numbers a record), `S.storeN`, `S.storeHash` (an int); `WorldStore.add(S, px, py, pz, r, depth, rim, energy, cause, owner, t, special) -> index or -1 when full`, `WorldStore.heightDelta(S, qx, qy, qz)`. The grid is derived and rebuilds itself on any restored state.
- **Craters (order of 2026-11-01):** `WorldCrater._dig` calls `_record`: on a gen 3 state with the store fields it adds the crater at the planet point of its strip x (`WorldCrater.pointHook`, a Callable Simulation sets: `func(S, x, z) -> [x, y, z]`; without it the match's own ring). With **no frame** on the state the strip's deform is written as ever and the crater is also in the store (nothing double counted, because nothing reads the store yet). With **`S.frame` not null** the strip's bowl, skid furrow, relaxation and neighbour rows are not written: the ground is the field plus the store. The crater record in `S.craters` (events, repeats) is kept either way. `deepen` still deepens the strip's deform (a buried fighter's follow-up); in a frame it needs the store to deepen the record: a follow-up for Simulation.
- Records: `S.fieldRecs` from `WorldField.recordsOf(P, ids)`; `WorldField.applyRecords(S, qx, qy, qz, h)`.
- Rendering's four, answered in `docs/world/gen3-field.md`.

## Decisions I made

1. A node is a ring column's value (surface plus detail): gen 3 is gen 2's ground sampled. Places, picker and climate stay the planet's.
2. The bake is nested in the canonical lattice (every fourth node).
3. Edges by refining creased cells (exact at 32 u, faded correction in neighbours), not polylines: shore displacement 95 to 16 units RMS, column RMS 9.55 to 3.34, no crack, about 140 ms a Half ring.
4. Planet-keyed trees use a planet cell of a quarter canonical cell (32 u).
5. **A town by plan is turned to the ring it is first laid on** (`plans.align`): a keyed street yaw stood only about half the chord layout (the lanes are cut to blocks along the line), and the aligned plan stands 46/46, 173/169, 129/105, 55/47, 13/9, 124/117 (planets and touches 7/1, 7/2, 3/1, 3/2, 11/1, 25/1). The cost: the street's compass direction depends on the match's ring (same buildings, plan indices, wear). `plans.align` false restores the planet-keyed yaw and about half the density.
6. Depth sign: the sim's z is positive toward the camera; plan code uses `-lateral()` and `pointAtX(x, z)` takes the sim's z. No `farColumn` or `farPlaces` z reaches the sim.
7. The rename `bell_tower` to `clock_tower` changes the settlements data hash (so a replay header made before it names other data) but no golden key.

## NEEDS FROM EP

- Simulation: skip `grant-simulation-state.patch` at landing (its install has the fields), `pointHook` is unneeded, `deepen` is done by its install; the digest folding `storeN` and `storeHash`, the 64-node sample in the match key, `pointHook`, and reading `applyRecords`/`bDir` in the frame.
- Rendering: the grant (both files). Art: `art/concepts/world/gen.mjs` still names `bell_tower`.
- Encounter: the director's candidate lists and arrival scores skip a building whose `WorldSettle.noTarget(b.landmark)` is true (RL-214, before main goes public).
- Orb's look: plans (staircase of lanes at an oblique swing; footprints are not rotated), and whether the smoother ground (refine on, 128 units) reads right.

## RISKS

- A building's `dir` is its plan point; its laid z is snapped flush into the lane, so about 30 percent stand 130 to 300 u in depth from it. Simulation overwrites `bDir` from the laid pose (their reconciliation), so nothing reads the difference; noted, not changed.

- The platform record is a disc under the place, where today's platform is the chord's span.
- Lakes and rivers are still planned on the ring's line (stage 8); the calm turn still lays new places from the chord; cities are frozen where the ring first meets them.
- Cells on a face's rim are never refined (about 1 percent of cells).
- Gates are finished for the whole stack (above). Land `grant-rendering.patch` with diff 5, or `shape_check` fails.

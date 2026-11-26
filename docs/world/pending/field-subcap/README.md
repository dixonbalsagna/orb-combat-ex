# Park: a size cap on the field's sub-node tables (World, 2026-11-26)

QA's hour run (`1e6048e2`) found World's `Field.sh` and `Field.sb` (sim/world/field.gd) growing without limit: every sub-node ever read stayed, 19 MiB each after one 600 s match, and more on every replay of a seed. This park bounds them. Nothing is applied to main.

| File | What |
| :--- | :--- |
| `field-subcap.diff` | `sim/world/field.gd` (the cap), `sim/world/field_pool.gd` (the pool writes from its own arrays), new `sim/world/tools/field_subcap_check.gd` (`FIELD_SUBCAP`) and its `.uid` |
| `grant-tools-field-subcap.patch` | Tools': `tools/world-checks.json`, the check's name |

## Is anything in sh or sb more than a cache?

No. They are never hashed, saved as state or read for a decision about whether to do something. Two readers set the rules for dropping: `_sampleRefined` and `_edgeDelta` index the tables just after `_subKey` returns a key (so nothing is dropped between), and `WorldFieldPool.store` wrote the on-disk pool from them (it now writes the same bytes from its own arrays). `F.subReads` is a count read by tools only.

## The design

Two generations, not a rebuild (walking 200,000 keys to rebuild would be a hitch of its own).
- When `sh` reaches `SUB_GEN` entries, **at the start of `_sampleRefined` or `_edgeDelta` only**, `sh`, `sb` become `shOld`, `sbOld` and new tables start (a swap, no copying).
- A key found in the old generation is carried into the new one without being computed. What a whole generation never read is dropped at the next turn, and read from the planet again if asked: the same value to the bit.
- The pool's keys and values are kept apart (`extraSub`, new `extraSubH`, `extraSubB`; about 1 MiB), listed only before the first turn, so none is listed twice.
- The old pool-cap, canonical nodes and the pool file's format are unchanged.

**`SUB_GEN` 150,000.** A match computes sub-nodes at about 150,000 in the first 150 to 230 s and about 200,000 by five minutes (`runs/field-subcap/before-run2-timed.txt`). Nothing is dropped until the second turn, which came at about 420 s in a 557 s match, so a normal match recomputes nothing. At most 2 x 150,000 entries in each table, about 37 MiB a field (64 bytes an entry, measured), however many matches; today one long match already holds 34 to 38 MiB and goes on.

## Measured (QA's `qa/soak/real-memory.mjs`, the real game headless, the computer against itself; one match capped at 600 s, then a reading 20 s into the next; `runs/field-subcap/`)

The matches are not the same match from run to run (their seeds differ), and the machine was shared (4 to 8 other Godot processes), so read the timings as "no difference seen", not as a benchmark.

| | Before | After (150,000) |
| :--- | ---: | ---: |
| `sh` + `sb` (+ old generation) after one long match, real memory freed by emptying them | 38.3 MiB (run 1), 34.4 MiB (run 2) | 18.9 MiB, plus 0.5 MiB of pool arrays |
| Ceiling for a field | none | about 37 MiB |
| Sim step, mean of 30 s windows (ms) | 1.06 | 1.08 |
| Sim step, median p50 / average p99 (ms) | 0.93 / 4.11 | 0.95 / 4.53 |
| Sub-nodes computed again | none | **0 until the second turn at about 420 s; 323 of 375,200 by 557 s** |

The step is the host's `SimCore.step` cost of each tick (a scratch timer, `step-timer-edit.js.txt`, never in a tree). At 30,000 (first try) the tables turned every 25 s and recomputed most of what they held; at 100,000 the match turned twice.

## Gates

All on HEAD with the diff and the grant (`runs/field-subcap/`): the golden check passes, unmoved; the 96 World checks pass; `SUBCAP` (the new check, 7 rows) passes through the gate and its `--negative-control` (never turning) fails the size row; `validate` 0 errors, self-test 10191 of 10191.

`SUBCAP` proves that with a generation of 400 every height, biome and fine biome is bit for bit what it is with nothing dropped, both passes (15,120 values over 504 refined cells, 48 turns); the tables stay within two generations; the pool list stays whole and right; and two 900-tick matches, one dropping all the time and one never, end in the same state.

## RISKS

- The memory bound is per field, and three fields (planet and size) can be held: about 110 MiB in the worst case, if a player plays three long matches on three planets or sizes. Today it has no bound.
- A rollback that reaches back across a turn recomputes what was dropped. The values are the same; only the cost.
- The pool file takes the sub-nodes of the first generation only (before: the first 60,000 of the whole session). The ring read at a load is a few thousand.
- `reliefClamp` in a node's read depends on the planet size in force, as it did on the first read: nothing new, but a re-read under another size would differ. Sizes have their own fields.

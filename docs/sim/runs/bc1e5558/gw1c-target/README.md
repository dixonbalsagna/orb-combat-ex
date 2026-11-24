# GW1c's target golden: the one re-record

Simulation, 2026-11-23 (the EP's order). When GW1c lands, main must reproduce this record bit for bit.

## The target

**`golden-target.json`**, sha256 `55bca55b25cb25a4f0cc987934242e2cef8956ca9ded0119a5037c562eca1e71`, 1,863,845 bytes. Godot 4.7.2-stable (official), headless. **Made from a cold field cache and again warm: one file.**

## The tree

A clean `git archive` export of main **bc1e5558**, then the 22 lines of `docs/ep/reviews/GW1c-stack.txt` in order.
- Each file's sha1 was checked against the list, and each applied strictly with `git -c core.autocrlf=false -c core.eol=lf apply`. All 22 applied.
- `relief-cap-data.diff` is not in it.
- `sizes.json` offers medium only.
- This is my own copy, built the same way as the EP's `s436`.

## Which entries move, and why (`golden-moves.txt`)

**Every move is the three store pieces'.** This golden is byte for byte the golden of main d0e48be5 plus only `globe-step2.diff`, `grant-simulation-field.patch` and `swap-blocks-gw1c.diff` (the bisect, `docs/sim/runs/d0e48be5/gw1c-bisect/`). Main's golden is the same at d0e48be5 and bc1e5558. So the other 19 lines leave it byte for byte.

| Entry | Moves? | Why |
| :--- | :--- | :--- |
| tick-0 states, tick-0 values, the intro and composed intro hashes | yes | the store fold: a store record now folds 16 numbers, not 12, and the planet's store holds the intro's two entrance craters at tick 0 |
| 7 planet matches (seeds 1 and 2) | yes, from tick 0 | the same fold. Six of them (all but mirror-villain-flip seed 2) also move in their per-tick digest, so their play moves after blows: globe-step2's groove storage |
| mirror-villain-flip seed 2, and the planet match (seed 29) | the full state only | the fold. Their per-tick digests don't move, so their play is unchanged |
| the two arena matches, both scripted replays, the planet slices, the planet tick-0 states | no | the hand-made arena has no planet store |

Nothing else moves.

## Proof

| Run | Result | Record |
| :--- | :--- | :--- |
| import | exit 0, no parse error | `records/import.txt` |
| golden, cold then warm | one file | `records/run.log` |
| **parity through `tools/gate.mjs`** against the new golden | **exit 0, 88 rows, golden check passed, no SCRIPT ERROR lines** (replay-sizes' sized-replay row included) | `records/parity.txt` |
| Rendering's 15 | all pass | `records/render15/` |

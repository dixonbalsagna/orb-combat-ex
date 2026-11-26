# GW1c's target golden, second cut (with World's bury fix)

Simulation, 2026-11-23 evening (the EP's order). When GW1c lands, main must reproduce this record bit for bit. It replaces `../gw1c-target/` (sha256 55bca55b), which was cut before the bury fix joined the stack.

## The target

**`golden-target.json`**, sha256 `2e8cdeaa917fdb5381b27f38796ef137dfb5d98b937a2b5a08d52b62e5fb1e7a`, 1,863,845 bytes. Godot 4.7.2-stable (official), headless. **Made from a cold field cache and again warm: one file.**

## The tree

A clean `git archive` export of main **bc1e5558**, then the 28 lines of `docs/ep/reviews/GW1c-stack.txt` in order.
- Each file's sha1 was checked against the list, and each applied strictly with `git -c core.autocrlf=false -c core.eol=lf apply`. All 28 applied.
- The six new lines are Camera's keep-human-vertical, World's `grant-simulation-crater-refused.patch` (reviewed: yes), `bury-refused.diff` and Tools' `grant-tools-bury-check.patch`.
- `sizes.json` offers medium only. Import: exit 0, no parse errors.
- This is my own copy, built the same way as the EP's `s437`.

## Which entries move against the first target (`golden-moves.txt`)

Only three matches move, and only in their per-tick digest. Their full-state checkpoints and final states don't move. These are exactly the three World measured (`docs/world/runs/bury-refused/`).

| Entry | Why |
| :--- | :--- |
| mirror-villain seed 1 (the planet) | the bury: a refused dig still buries him |
| swap-flip seed 2 (the planet) | the bury |
| default seed 11 (the arena) | the new `crater_refused` event, which folds into the digest |

Everything else matches the first target byte for byte: the tick-0 entries, the other six planet matches, the planet match (seed 29), the first arena match, both replays, the planet slices and the planet tick-0 states. So against main bc1e5558 (`golden-moves-vs-main.txt`), the moves are the first target's, which the bisect explained (`docs/sim/runs/d0e48be5/gw1c-bisect/`), plus these three.

## Proof

| Run | Result | Record |
| :--- | :--- | :--- |
| import | exit 0, no parse error | `records/import.txt` |
| golden, cold then warm | one file, no script errors | `records/run.log`, `records/golden_cold.txt`, `records/golden_warm.txt` |
| **parity through `tools/gate.mjs`** against this golden | **exit 0, 88 rows, 0 FAIL, golden check passed, no SCRIPT ERROR lines** (2026-11-25) | `records/parity.txt`, `records/run-restart.log` |
| Rendering's 15 | all pass (2026-11-25) | `records/render15/` |

On 2026-11-23, Orb's safe pause stopped the runner by its own PID between the cold golden and parity. The cold golden ran to its end, and the warm golden and the moves were run after it (`records/g1c2_finish.sh.txt`). Parity and Rendering's 15 ran on the same tree on 2026-11-25, after the restart (`records/g1c2_par.sh.txt`). Its `golden.json` was checked equal to this target first.

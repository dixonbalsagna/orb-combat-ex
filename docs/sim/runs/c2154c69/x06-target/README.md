# X-06's target golden: the re-record for the bands (Medium, the hold answer)

Simulation, 2026-11-22 (the EP's order: X-06 lands in its own window). When X-06 lands, main must reproduce this record bit for bit. GitHub sign-in on this PC has expired, so nothing reaches CI until it's renewed. This local gate is the proof.

## The target

**`golden-target.json`**, sha256 `6b3e14c27a63d1086b9173d66f842016c59da7f444bd15f96f2cb4ef9dee47db`, 1,863,845 bytes. Godot 4.7.2-stable (official), headless. **Made from a cold field cache and again warm: one file.**

## The tree

A clean `git archive` export of main **c2154c69**, then `docs/director/pending/x06-bands/` in its README's order, each with `git -c core.autocrlf=false -c core.eol=lf apply`. All three applied with no error:
1. `x06-medium.diff`, sha1 ccea61aa4a4ad224712ce88f6f8778e497e1dee9;
2. `x06-hold-answer.diff`, sha1 b19a27cf4895f9d4e8a68de46e2bb52a9141ec0e;
3. `x06-hold-answer-schema.diff`, sha1 1e83ef347849dc1edc7b7712e0896dbe02b0d17b.

The three commits after c2154c69 on main (5d4359b9, 438819cd, 2e3407dc) change only docs, and main's golden is c2154c69's byte for byte.

## Which entries move (`golden-moves.txt`)

| Entry | Moves? | First difference |
| :--- | :--- | :--- |
| matches[0] default seed 1, the arena | yes | tick 960, state |
| matches[1] swap seed 1, the planet | yes | tick 1800, state |
| matches[2] mirror-villain seed 1, the planet | yes | tick 960, state |
| matches[3] mirror-hero seed 1, the planet | yes | tick 840 |
| matches[4] default-flip seed 2, the planet | yes | tick 840 |
| matches[5] swap-flip seed 2, the planet | yes | tick 360 |
| matches[6] mirror-villain-flip seed 2, the planet | yes | tick 360 |
| matches[7] mirror-hero-flip seed 2, the planet | yes | tick 5880 |
| matches[8] default seed 11, the arena | yes | tick 1440 |
| replays[0] seed 11 (a scripted P1 against the computer) | yes | tick 120 |
| replays[1] seed 12 (two scripted players, no computer) | the full-state hash only | tick 120, state. Its per-tick digest and its length are unchanged: play is the same, and a newly hashed field carries a value |
| the planet's slices, tick-0 states, and its match (seed 29, 3,600 ticks) | no | |
| every other key (constants, rng, tick-0, intro, wounds, ...) | no | |

Every computer-played match moves, as a change to the computer's Medium level and its answer to holds should. The two-player replay moves only in its full state, so no human's play changed.

## Proof

| Run | Result | Record |
| :--- | :--- | :--- |
| import | exit 0, no parse error | `records/import.txt` |
| golden, cold then warm | one file | `records/run.log` |
| **parity through `tools/gate.mjs`** against the new golden | **exit 0, 87 rows, golden check passed, no SCRIPT ERROR lines** | `records/parity.txt` |
| Rendering's 15 | all pass | `records/render15/` |

**Not covered here:** the director checks, the bands' own checks and QA's cells (Encounter's and QA's records in `docs/director/pending/x06-bands/`), and CI.

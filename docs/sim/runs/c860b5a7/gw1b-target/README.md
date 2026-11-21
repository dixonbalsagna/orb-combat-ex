# GW1b's target golden: the one re-record (A-CODE-02)

Simulation, 2026-11-21, sprint A1 (the EP's NB-1, `docs/ep/reviews/GW1b-recheck.md`). Main must reproduce this record bit for bit once GW1b lands.

## The target

**`golden-target.json`**, sha256 `833df9ef5df4e5eff7c6af5e8a636ce122336894a09ec85d0dbe53b4b0f1067f`, 1,863,845 bytes: 9 matches (187,200 ticks), 2 replays, 6 tick-0 states, 60 constants, 8 rng streams, and the planet entry. Godot 4.7.2-stable (official), headless.

- **Made from a cold field cache and again warm: one file** (`records/golden_cold.txt`, `records/golden_warm.txt`).
- **The planet match** is planet 7, touch 3, generation 3, seed 29, 3,600 ticks. It keeps its first crater (tick 739) and its first slide (tick 1922) on this tree, and parity asks for both.
- **The recipes:** default seed 1 and seed 11's KO match take `"world": "arena"`, and so do both scripted replays. The other seven matches name no world, so they play the planet the game starts on.

## The tree

A clean `git archive` export of main **c860b5a7**, then:
1. **the 44 lines** (`records/the-44-lines.txt`): every `ap` line of `docs/ep/reviews/GW1b-stack.txt` except the lake group (its lines 82 to 85, out of GW1b by the EP's ruling). Each one is applied in order with `git -c core.autocrlf=false apply`. All 44 applied, with no error. The flip (`data-switches-gw1b.diff`) is last, and `world.json` reads `"mode": "planet"`;
2. **then `docs/architecture/pending/gw1b-golden/gw1b-golden.patch`** (re-cut on this tree after the flip; see its README).

## Proof

| Run | Result | Record |
| :--- | :--- | :--- |
| import | exit 0, no parse error | `records/import.txt` |
| golden, cold then warm | one file | `records/run1.log` |
| parity through `tools/gate.mjs`, first pass | exit 1: two rows written for the hand-made arena (below) | `records/parity.txt` |
| **parity through `tools/gate.mjs`, with the two rows fixed** | **exit 0, 86 rows ok, golden check passed, no SCRIPT ERROR lines** | `records/parity2.txt`, `records/run2-parity.log` |
| `frame_check`, `cross_check`, `cross_end_check` | pass | `records/` |
| Rendering's 15 (`after_check` to `stage_check`, `cue_check --profile=spaced`) | all pass, `ground_check` included | `records/render15/`, `records/run1.log` |

**The two rows parity's first pass found** (my tests, fixed in the re-cut; `records/probes.txt`):
- **"the last stand"** failed in arena mode too, so the flip didn't cause it. Encounter's stray-beams (line 21 of the 44) makes RT + B the signature only when RT is pressed on that tick or inside its window. The row held RT but didn't press it. With RT pressed, the free signature fires and every expectation holds, so the game is right. The row now presses RT on the tick, as stray-beams did for four director checks.
- **"the curve's shared functions"**: predict() and the flight are at the same place every tick. On a field world, predict() reads the far ground (every farStride-th column, interpolated), so its touchdown came a tick early: 256 against 257. The row asks for the same tick, which holds only where the ground has one read, the hand-made arena. It now runs there.

**parity-lake-unpin (line 73) belongs without the lakes.** Its row is planet 3, generation 2's own lake touch-down, not a lake-places lake. It depends on World's floor rise (line 70, in the list). It passes: "a match starts on the floor of a lake or the sea".

**Not covered here:**
- the full gate (the EP's next step);
- QA's reference lanes on the new golden;
- `fights_check` (its "swings rest while apart" fails on main as it stands; mine, after GW1b).

The import made `.uid` files for four new tool scripts in the stack: Director's `bounce_count`, `launch_cone_check` and World's `default_gate_check`, `floor_rise_check`. Godot writes them on any import; they aren't in the parks.

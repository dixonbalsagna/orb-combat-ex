# The moveset coverage probe (A-CONTROLS-06, X-03)

Owner: Controls. Park: `docs/controls/pending/coverage-probe/` (`sim/input/tools/coverage_probe.gd`, `coverage_cells.json`). First reading: `docs/controls/runs/51b840f5/coverage-kept-6a30b4c9-reading.txt`. It changes nothing in the sim.

## What it does

A scripted pad presses every cell of the move table in a live match, through the real hub into `SimCore`, once per fighter, and writes one line per cell:

| Line | Means |
|---|---|
| `OUTCOME ...` | the press did something no earlier cell did: the exchange's template, the attacker's pieces, the kinds of hit, the pad fighter's events, any act or state change |
| `SAME AS <cell>` | the whole outcome is an earlier cell's, event for event |
| `SAME MOVE AS <cell> (... also <events>)` | the same template, pieces and hit kinds as an earlier cell, plus a side effect the layer adds (LB's stance check, a beam's stages) |
| `REFUSED <reason>` | nothing happened and the build said so (a `stick_refused` or `press_refused` cue, or the hub's own row, such as `charging`) |
| `NOTHING` | a silent press: nothing happened and nothing was said |
| `... (by design: <sentence>)` | an empty cell Combat's design page names as empty on purpose, from the cell's `by_design` field |

`COUNT` lines: per fighter, the cells, the own outcomes, the repeats of each kind, the refused and the silent ones; "no outcome" is refused plus silent.

## The cells (101, the same count as the audit's table)

`coverage_cells.json`, one object per cell: five held layers (none, LB, RB, RT, LT) by four face buttons (X light, Y heavy, B signature, A context) by three ways of pressing (tap, mash, hold) = 60; the right stick (none 9: flick up, down, down in the air, toward, away and hold in four ways; LB 8; LT 8; RB 8; RT 2) = 35; six pairs (X + Y, LT + RT, LB + LT, LB + RB, LT + RB, B + X on one tick) = 6. Each cell carries the pad events that press it (`pre`: the held layer before; `script`: the press) and an empty `by_design` string. **Combat's list is routed through the EP:** the EP sends Combat this file, Combat fills `by_design` for the cells that are empty on purpose, and any cell the table has that is missing here is added. The tool counts what is in the file; nothing in its code names a cell.

## How to run it

```
godot --headless --path <tree> --script res://sim/input/tools/coverage_probe.gd -- --fighters=PROTAGONIST,RIVAL
```
Options: `--seeds=5,11,23` (a pool picks its piece by the seed, so a cell is read over three seeds and its outcome is the union), `--dist=250` (the opponent's distance; at 80 the match opens in a clinch and the first press only ends it), `--cells=<json>`, `--only=<id substring>`, `--trace=<cell id>` (every event and feed line of that cell, to read why it reads as it does). About 100 seconds for both fighters, one job.

**It reads the build's data, not main's.** Run it against the tree a build was made from (its `sim/` and `data/`), or a desktop build's pack (`--main-pack build.pck --script ...`), and everything comes from `res://`. Nothing is pinned or set in memory: the pad is exactly the data's. The first lines print the fighters' data hash, `data/input/timing.json`'s hash and the switches that are on, so a reading says which build it is of.

## How a cell is read

A fresh match per cell and seed: the fighter under test is slot 0 on the pad, a standing opponent 250 units away, 30 ticks to settle, the layer pressed, then 90 ticks of the script. The layer alone (no press) is read first and subtracted, so holding LB is not an outcome of every LB cell. Determinism: two readings of one tree are byte-identical.

## To add a cell when the table changes (A4)

Add an object to `coverage_cells.json`: an `id` (`layer/button/press`, `layer/stick/flick|hold/direction`, `pair/name`), its `layer` (`none`, `LB`, `RB`, `RT`, `LT` or `pair`: the layer's held buttons are the baseline), `kind`, `pre` and `script` (events: `[tick, "b", control, down]`, `[tick, "t", control, value]`, `[tick, "ls" or "rs", "", x, y]`; negative ticks come before the press), and `by_design` if the cell is meant to be empty. A new fighter is a new `--fighters` id. A new held layer needs its baseline: add a layer name to the list in `_fighter` (one line).

## First reading: the kept 9 November build, both fighters

Per fighter: 101 cells; PROTAGONIST 53 own outcomes, 32 same as an earlier cell, 11 the same move with another side effect, 2 refused, 3 silent; RIVAL 52, 32, 12, 2, 3. **No outcome: 5 cells** (the silent three are the A button with LB held, tap, mash and hold; the refused two are the right stick pushed with RT held, which says "Charging"). **Repeats: 32 as the same outcome, 43 or 44 counting the same move.** Where they come from:
- RT and LT with X, Y and A repeat the no-layer row (RT and LT bring nothing to those buttons); LT with B is the big heavy as with no layer.
- LB with B repeats LB with Y (B is sent as Y); LB with X and Y are the no-layer blows plus a stance check or push.
- RB with B: the Driver (tap and mash are one outcome, a hold adds the charge stages); RB with A: the mine.
- The A button held and mashed repeats A tapped (a taunt).
- The RB stick's hold in four directions is the signature template, the same move as RT with B.
- The stick's quick flicks are the same lunge and blow in every layer but the pieces differ by direction and layer; the stick down in the air repeats the grounded down flick.

## Why these numbers differ from the audit's 18 and 65

The audit's count (`reads/RR-01.md`) is a static tabulation of what the data names: a cell is "not found" when no entry keys it. The probe presses the cells. A hold or a mash of X, Y or B finds no entry of its own in the table yet plays blows in a brawl, so it reads as an outcome; two cells that share an entry in the data can still play different pieces by the seed, so they read as distinct. Neither count is wrong; the probe's is what a player gets. Combat's `by_design` notes will make the five silent cells and the 32 repeats into "on purpose" or "to build", which is X-03's count.

## Not done

- The reading is at one distance (250) and one opponent behaviour (standing). A move that needs a different range (a grab, a throw, an air blow) reads as what it does from there.
- Not in CI. The reading is wanted on every build from A2; a CI step is a 100-second Godot job on the packed build, which is Tools' to add (`docs/controls/pending/coverage-probe/README.md`).

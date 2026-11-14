# The moveset coverage probe (A-CONTROLS-06, X-03)

Owner: Controls. Park: `docs/controls/pending/coverage-probe/` (`sim/input/tools/coverage_probe.gd`, `coverage_cells.json`). Reading: `docs/controls/runs/51b840f5/coverage-kept-6a30b4c9-reading.txt`. It changes nothing in the sim.

## What it does

A scripted pad presses every cell of the move table in a live match, through the real hub into `SimCore`, once per fighter, and writes one line per cell:

| Line | Means |
|---|---|
| `OUTCOME ...` | the press did something no earlier cell did: the exchange's template, the attacker's pieces, the kinds of hit, the pad fighter's events, any act or state change |
| `SAME AS <cell>` | the whole outcome is an earlier cell's, event for event |
| `SAME MOVE AS <cell> (... also <events>)` | the same template, pieces and hit kinds as an earlier cell, plus a side effect the layer adds (LB's stance check, a beam's stages) |
| `REFUSED <reason>` | nothing happened and the build said so (a `stick_refused` or `press_refused` cue, or the hub's own row, such as `charging`) |
| `NOTHING` | a silent press: nothing happened and nothing was said |
| `... (by design: <sentence>)` | on any line: the cell's `by_design` sentence, from Combat's design page (empty or shared on purpose) |
| `... (proposed, not by design yet: <sentence>)` | on any line: Combat's `proposed` share, which Game Design has to write into the design page before it counts |

`COUNT` lines: per fighter, the cells, the own outcomes, the repeats of each kind, the refused and the silent ones; "no outcome" is refused plus silent. **`EXPLAINED` lines are X-03's count:** no outcome and repeats, split into by design, proposed and unexplained.

## The cells (116, Combat's file)

`coverage_cells.json` is Combat's S4 file (`docs/combat/pending/move-table/coverage_cells.json`), unchanged in content: the 101 cells (five held layers by four face buttons by three presses = 60; the right stick 35; six pairs) plus Combat's 15 (the catch and the in-reach layers, the air cells, the charge-up, the dodge, the snare), each with `by_design` filled where a design page says so, and Combat's `combat`, `proposed`, `note` and `added_by` fields. The probe reads `by_design` and `proposed` and ignores the rest. Each cell carries the pad events that press it (`pre`: the held layer or the setup before; `script`: the press). **The layers are the ones the cells name:** `none`, `LB`, `RB`, `RT`, `LT`, `brawl`, `brawlLT`, `brawlLB`, `air`, `pair`; each layer's baseline (its `pre` with no press) is read and subtracted, so there is no list to edit in the code. An air cell (layer `air`, or `in_air` true) is a fight in the air: the pre lifts the fighter and the foe is brought to his height as the press is made.

## How to run it

```
godot --headless --path <tree> --script res://sim/input/tools/coverage_probe.gd -- --fighters=PROTAGONIST,RIVAL
```
Options: `--seeds=5,11,23` (a pool picks its piece by the seed, so a cell is read over three seeds and its outcome is the union), `--dist=250` (the opponent's distance), `--cells=<json>`, `--only=<id substring>`, `--trace=<cell id>` (every event and feed line of that cell and the fighter's height, to read why it reads as it does). About two minutes for both fighters, one job.

**It reads the build's data, not main's.** Run it against the tree a build was made from (its `sim/` and `data/`), or a desktop build's pack (`--main-pack build.pck --script ...`), and everything comes from `res://`. Nothing is pinned or set in memory: the pad is exactly the data's. The first lines print the fighters' data hash, `data/input/timing.json`'s hash and the switches that are on, so a reading says which build it is of.

## How a cell is read, and the traps it avoids

A fresh match per cell and seed: the fighter under test is slot 0 on the pad, a standing opponent 250 units away, both put on the floor, 30 ticks to settle, the cell's `pre` (from tick -80) and then 90 ticks of its script. The layer alone is subtracted. Determinism: two readings of one tree are byte-identical. Three traps Combat found are fixed:
- **The fighter starts above the floor** in a new match, so the grounded down flick was never read (both down cells read the air version). Both fighters are now put on the floor, and the air cells lift the fighter and bring the foe to him: the grounded down flick plays `scythe_sweep`, the air one `spike_heel` and the slam hint.
- **Joining with A opened a taunt** in every match. The joining press is now spent off the sim, so nothing precedes the press.
- **At 100 units the match opens in a clinch** and the first press only ends it. A clinch the opening makes is now waited out (up to 400 ticks, until 40 are quiet), so `--dist=100` reads a blow.

## To add a cell when the table changes (A4)

Add an object to `coverage_cells.json`: an `id` (`layer/button/press`, `layer/stick/flick|hold/direction`, `pair/name`), its `layer` (a held layer, or a new name: the probe reads the baseline of whatever layer the cells name, from the first cell of that layer's `pre`), `kind`, `pre` and `script` (events: `[tick, "b", control, down]`, `[tick, "t", control, value]`, `[tick, "ls" or "rs", "", x, y]`; negative ticks come before the press, the earliest -80), and `by_design` if the cell is meant to be empty or shared. A new fighter is a new `--fighters` id. When Combat changes the table the file is theirs and the probe is unchanged.

## The reading: the kept 9 November build, both fighters

Per fighter, 116 cells. PROTAGONIST: 63 own outcomes, 37 same as an earlier cell, 11 the same move with another side effect, 2 refused, 3 silent; RIVAL 62, 37, 12, 2, 3. **No outcome: 5 cells, none explained** (the silent three are the A button with LB held; the refused two are the right stick pushed with RT held, which says "Charging"). **Repeats: 37 as the same outcome, 48 or 49 counting the same move; 22 are by design, 19 proposed, 7 (PROTAGONIST) or 8 (RIVAL) unexplained.** The new cells read: the catch in the clinch, the in-reach layers, the air cells distinct from the grounded ones, the charge-up and the dodge as their own outcomes.

## Why these numbers differ from the audit's 18 and 65

The audit's count (`reads/RR-01.md`) is a static tabulation of what the data names: a cell is "not found" when no entry keys it. The probe presses the cells. A hold or a mash of X, Y or B finds no entry of its own in the table yet plays blows in a brawl, so it reads as an outcome; two cells that share an entry in the data can still play different pieces by the seed, so they read as distinct. Neither count is wrong; the probe's is what a player gets.

## Not done

- One opponent behaviour (standing) and one distance (250) for most cells; the in-reach cells open their own brawl by an X tap at -40. A move that needs another range (a grab thrown from far, a throw) reads as what it does from there.
- Not in CI. The reading is wanted on every build from A2; a CI step is a two-minute Godot job on the packed build, which is Tools' to add (`docs/controls/pending/coverage-probe/README.md`).

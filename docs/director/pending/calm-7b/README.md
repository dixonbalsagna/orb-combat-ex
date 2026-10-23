# The calm turn: a landing's moment from the journey's end (parked, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 7b, on main's calm turn (a06f6920). A landing's moment starts at the end of his journey (the slide's end), not at his first contact. The window is `landedTicks` (45) live ticks from there, with both set (under 60 u/s) and nothing in flight. Before, it was the fighter's state clock, which the journey's end starts part way after a slide (0.75 s less World's recover), and a returning fighter's own clock.

The record is written only while the calm turn is on (`calmTurn.enabled` and World's turn), so the golden doesn't move.

## To build it

After 7a (`../press-wait/`; `DirCalm`'s slots follow `DirPress`'s): `node c7.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. The wall kick (`../wall-kick/`) applies after it: its slots follow these.

| File | Change |
| :--- | :--- |
| `sim/director/calm.gd` | Two slots: `CM_WAS` (his state at the director's last tick) and `CM_REST` (the live tick he came to rest). The new `DirCalm.tick` records the rest: down, or out of a flight into the water (a water landing counts). In `why()`, the landing holds within `landedTicks` of it |
| `sim/director/exchange.gd` | `DirCalm.tick(S)` in `dirUpdate`, after 4c's windows |

## What it read (main fcc537b9 plus the chain to 7b, in scratch; 10 AI matches a ring on planet 7)

| Ring | Turns | A match | Of them at a landing | Most ground moved | Bad, cold |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Whole (4,800) | 6 | 0.6 (as before 7b) | 0 | 148 | 0, 0 |
| Half (2,400) | 12 | **1.2** (1 or 2 every match) | 6 | 203 | 0, 0 |
| Close (1,200) | 11 | **1.1** (one match 0) | 3 | 282 | 0, 0 |
| Whole, World's ground rule at 450 (in memory: GD's next lever) | 7 | 0.7 | 1 | 398 | 0, 0 |

- **Half and Close meet Game Design's 1 to 3.** More of their turns come at landings now.
- **The Whole ring doesn't, even at 450.** Around its landings the hold is off for the warm (571 to 696 ticks: two rings of 4,800 at 16 a tick take 300) and for the ground rule (300 to 615). The next lever is Game Design's: a larger warm budget for a Whole landing, or a moment that lasts longer.
- **The gate list:** with the whole chain, in the chase park's run.

## Probe (`probes/ctp.gd`, from a copy's root, with window 3)

`ctp.gd -- <matches> <seed0> [--cols=4800] [--warmMax=32] [--moveMax=300] [--off]`. `--warmMax` and `--moveMax` set the budget and World's ground rule in memory.

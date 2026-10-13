# Depth, slice D1a: the drift, parked (2026-10-13)

Owner: Encounter Systems Director. The director's part of a brawl that stands on a line 10 to 30 degrees from the street and drifts in depth: the line's frame, the push and pull, the carry, the ease home, the cap and World's room. The sizing (sections 1 to 8) and D1a as built with its rows (section 9) are in `files/docs/director/depth-d1.md`, which is new and goes to `docs/director/`.

**It is a script and not files,** because it rewrites `sim/director/brawl.gd`, `bands.gd` and `exchange.gd` on top of the nine cells' chain, and adds its numbers under `director` in Simulation's `data/combat/depth.json`. Every anchor is exact text and the script stops if one is missing.

**To build it, in this order,** on a checkout that has the nine cells' chain (`../nine-cells-chain/`):
1. Simulation's part (a): `python docs/architecture/pending/depth-a/depth_a.py <root>` and `depth_a_checks.py <root>`.
2. `node d1a.cjs <root>`.
3. An import (Simulation's part adds a class).

**Proved on a fresh export of main 710b6905 with the chain,** in scratch:
- With depth off the golden regenerated is the chain's own, byte for byte. Simulation's parity checks pass, its two for depth among them. Determinism passes. The validator is clean.
- With depth on (a forced setup; three stick habits, 8 matches each from the crossing): the pair stands between 10 and 30 degrees on every tick, the drift never passes 1.2 bh a second, and no brawl goes through a face.

**Not gated beyond that.** The full gate list was not run with part (a) and D1a in: with depth off they are the chain to the bit, and depth on is no shipped setup yet.

**For Simulation:** my numbers for `data/combat/depth.json` under `director`: `lineSinMin` 0.1736, `lineSinMax` 0.5, `arriveSin` 0.342, `homeAfterTicks` 30, `homeBhPerSec` 0.5. The script adds them; they are Simulation's file to carry.

**For Game Design** (section 9): a stick held toward for a whole brawl changes street in one brawl of five; a blow's closing step moves the pair's middle past the drift's cap on 3 ticks in 1,000 (the core's `stepTo` has no cap, by its rule).

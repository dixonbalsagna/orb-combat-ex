# Planet generation 2, window 9: Simulation's two notes on window 8 (parked)

World and Environment, 2026-10-23. `gen2-w9.diff` (sha1 6a4069e52595, 2 files) is a git-apply diff. Applies after window 8 (order 2, 2b, 3, 4, 5, 6, 7, 8, 9).

1. `data/biomes/skate.json` is hashed as its parsed data without the `_` keys (`FighterData._canon`), as `contact.json` is, so a changed note keeps replays made with the skate on.
2. The reference run is its own function, `WorldContact._refRun(S, body)`, and `skate_check.gd` proves it writes nothing to the state: with it and without, the same state hash, random stream, terrain sum, craters and slides (one more check, 10 in all).

Files: `sim/world/contact.gd`, `sim/world/tools/skate_check.gd`.

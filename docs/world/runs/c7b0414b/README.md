# Runs: bystanders windows 1 and 2 (World, 2026-11-08), on main c7b0414b (no sim, data or schema file moved since 397a7adf) with Simulation's cd05-witness applied

CD-22. Park: `docs/world/pending/bystanders/`. A clean export of main, cd05's four patches, then the park's three patches (World, Simulation's, Encounter's), one Godot job at a time and never more than three. Logs are the verdict lines and the tails.

| File | What |
| :--- | :--- |
| `bystanders-check-passes.txt` | `BYSTANDERS: 0 check(s) failed` |
| `NEGATIVE-CONTROL-1-meter-gain-and-count-inside-scatter.txt` | a menace gain, a power gain and a count put back inside `scatter`: 26 FAIL lines |
| `NEGATIVE-CONTROL-2-emptied-gain-reads-who-is-inside.txt` | the emptied gain made to scale with who is inside: 4 FAIL lines (the same meters with every person taken out; the identity over a match) |
| `NEGATIVE-CONTROL-3-planner-read-reads-a-person.txt` | `livedMass` made to read a person: 3 FAIL lines (the identity over a match, which then also finds nothing fell) |
| `parity-before-regen-fails-as-meant.txt`, `parity-after-golden-regen-passes.txt` | the golden fails before it is regenerated and passes after (`golden-regen.patch` is the diff on cd05 plus this); the wired rows prove every new number in both `meters.json` changes a match |
| `checks-verdicts.txt` | the verdict line of every one of the 85 World checks and of the director and core subset |
| `ground-check-pins-from-the-stack.txt` | the six hashes `ground_check` is re-pinned to (taken from the stack) |
| `structure-mass-by-tier-summary.txt`, `structure-mass-by-tier-matches.txt` | the budget and ceiling measurements: 16 AI matches on the hand-made arena and 6 on planet 7, one line each |
| `old-feed-power-by-match-on-main.txt` | the old power feed on main, by match (instrumented copy of main): the calibration's other side |
| `step0-ocean-probe-tick-7380-7620.txt` | the replay of Orb's second Sunday play at the ticks of the ocean stills (World's side of terrain-plan step 0) |

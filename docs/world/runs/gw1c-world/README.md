# Runs: World's GW1c rows (World, 2026-11-14), park `docs/world/pending/gw1c-world/`

*The park this names, `docs/world/pending/gw1c-world/`, landed in GW1c (18878be9, 725b52ef) and was removed on 2026-11-25; git history has it.*

CD-22. Scratch trees of HEAD def3445a with the four parks applied in order (globe-step2, a-world-01, planet-sizes, gw1c-world); one Godot at a time at below-normal priority (two with parity). Logs are the verdict lines.

| File | What |
| :--- | :--- |
| `size-check-passes.txt` | `SIZES: 0 check(s) failed`: the five sizes, the cap, the spawn reach of all 75 spawns, the strict loader |
| `NEGATIVE-CONTROL-no-cap-no-spawn-reach.txt` | the data without the cap and the spawn reach: 3 FAIL (tiny and small's tallest 4,875; the farthest spawn 20,398) |
| `crater-flatten-check-passes.txt` | `CRATERFLATTEN: 0 check(s) failed`: 4 humps with the switch off, 0 on |
| `NEGATIVE-CONTROL-flatten-stays-off.txt` | the switch kept off: 2 FAIL |
| `checks-verdicts-all-89.txt` | every World check with the stack (see the README for the two re-runs) |
| `parity-passes-golden-unmoved.txt` | parity against main's golden: passes |

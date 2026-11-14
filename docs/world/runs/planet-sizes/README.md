# Runs: planet sizes (World, 2026-11-13/14), park `docs/world/pending/planet-sizes/`

CD-22. Scratch trees of HEAD def3445a with the three parks applied in order (globe-step2, a-world-01, planet-sizes), one Godot at a time at below-normal priority (at most two processes). Logs are the verdict lines and the tails.

| File | What |
| :--- | :--- |
| `size-check-passes.txt` | `SIZES: 0 check(s) failed` (26 ok lines): the five sizes play, the same setup twice, medium named against unnamed, a size the data lacks, the host's strict loader, the store's grid on the huge planet |
| `NEGATIVE-CONTROL-grid-offset-stays-64.txt` | the store's grid offset kept at medium's 64: 1 FAIL |
| `checks-verdicts-all-88.txt` | the verdict line of every World check with the three parks (shipped data): all 0 failed |
| `parity-passes-golden-unmoved.txt` | parity against main's golden: passes (medium is unchanged at 4,800) |

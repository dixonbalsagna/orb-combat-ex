# Runs: A-WORLD-01 (World, 2026-11-13/14), park `docs/world/pending/a-world-01/`

CD-22. Scratch trees of HEAD def3445a: globe-step2 applied, then this park; a second tree with the GW1a data flips for the flipped run. One Godot at a time at below-normal priority (at most two processes). Logs are the verdict lines and the tails.

| File | What |
| :--- | :--- |
| `world-default-check-passes.txt` | `WORLDDEFAULT: 0 check(s) failed` on the shipped data (arena mode); it passes on the flipped data too (planet mode) |
| `NEGATIVE-CONTROL-draw-ignores-the-seed.txt` | the quick-match draw made to ignore its seed: 1 FAIL (the spread check) |
| `flipped-data-checks.md` | the run list on the GW1a data: 44 pass unchanged, 41 fail (the first failing line of each), 2 stopped for slowness |
| `checks-verdicts-all-88.txt` | the verdict line of every World check on the shipped data, with all three parks: all 0 failed |
| `parity-passes-golden-unmoved.txt` | parity against main's golden: passes |

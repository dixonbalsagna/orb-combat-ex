# Runs: the wall that holds him, switched on (World, 2026-11-14), park `docs/world/pending/wall-hold-on/`

CD-22. A scratch tree of HEAD def3445a with globe-step2 applied and the park's data and re-pins; one Godot at a time at below-normal priority (two with parity). Logs are the verdict lines.

| File | What |
| :--- | :--- |
| `before-the-re-pin-5-pins-fail.txt` | the checks that read brunt.json with only the data flipped: `WALLHOLD` 1, `BRUNT` 1, `REPEAT` 2, `WALL` 1, each a pin of the old value (and `brunt_check`'s world hold); every other check that reads it passes |
| `checks-verdicts-all-86.txt` | every World check with the park (data and re-pins): all 0 failed |
| `parity-golden-moves.txt` | parity: the golden's matches differ from the first wall hit (tick 8,280 to 15,480), planet worlds identical: a hash window, as meant |

# Linux soak, two hours (Tools, read 2026-11-26)

Run 45773552777 on ac4ba152 (build 0.1.1), `seconds` 7200, headless, ubuntu-24.04; 2 h 2 min in all. **Success.** A stability and memory reading only (RL-279): no flash reading, no gate. QA's harness, `qa/soak/soak.mjs`.

**All seven checks passed:** computer both sides (719 samples); ran the 7,203 s and quit when asked; exit code 0; run marker gone; no SCRIPT ERROR; median 60.0 ticks a second (5th percentile 59.9); 13 matches started (7 wanted). 11 ended (6 KO, 5 capped), median 578 sim seconds. First match up 12.6 s after start.

| Memory (from outside), MiB | after warm-up (720 s) | end | max | slope, MiB an hour |
|---|---|---|---|---|
| resident | 383.6 | 600.4 | 600.4 | 142.3 |
| data | 443.7 | 660.4 | 660.4 | 142.2 |

| Match | began at, s | objects at start | resident 20 s in, MiB |
|---|---|---|---|
| 2 | 673 | 17,921 | 383.6 |
| 3 | 1359 | 17,993 | 400.8 |
| 4 | 2045 | 18,031 | 443.7 |
| 5 | 2731 | 18,072 | 463.5 |
| 6 | 3289 | 18,109 | 507.3 |
| 7 | 3968 | 18,150 | 560.9 |
| 8 | 4561 | 18,157 | 566.1 |
| 9 | 5245 | 18,177 | 580.7 |
| 10 | 5773 | 18,210 | 585.5 |
| 11 | 6360 | 18,245 | 597.9 |
| 12 | 6903 | 18,268 | 600.3 |

Memory rose in every match start read, by about 217 MiB from the second to the twelfth. The rises were smaller in the last five (2 to 17 MiB each) than in the middle (up to 54), so it may be levelling; two hours does not show that it does. Objects at match start rose by 7 to 72 each time, 347 in all. Resources 396 throughout, orphans 0. **Not judged here:** the memory budget is Performance's.

Frames: worst frame in a window 23.2 ms median, 1,559 ms at most. At exit, one ERROR (10 resources still in use) and one WARNING (304 objects leaked). Report scan: 3 files, 0 findings.

# Linux soak, first dispatch (Tools, read 2026-11-25)

Run 45760808694 on cae303f2, `seconds` 600, headless, ubuntu-24.04. **Success.** A stability and memory reading only (RL-279): no flash reading, no gate. QA's harness, `qa/soak/soak.mjs`. This was a 10-minute trial, not the two-hour soak.

All six checks passed: the computer played both sides (60 samples); it ran the 600 s and quit when asked; exit code 0; the run marker was gone; no SCRIPT ERROR; median 60.0 ticks a second (5th percentile 59.4). The first match was up 18.1 s after start.

| Memory (from outside), MiB | after warm-up (120 s) | end | max | slope, MiB an hour |
|---|---|---|---|---|
| resident | 359.9 | 368.1 | 368.1 | 58.3 |
| data | 420.0 | 428.1 | 428.1 | 57.9 |

Do not read the slope on a 10-minute run. Objects 13,513 to 13,800 (max 13,920), nodes 1,264 to 1,274, resources 393, orphans 0. Frames: worst frame in a window 27.6 ms median.

Two ERROR lines, both at exit (13 resources still in use; 6 dummy-renderer textures leaked), the same kind QA saw on Windows. Report scan: 3 files, 0 findings. The probe was not in the exported program. The whole run took 18 minutes, so a 7,200 s run should take about 128 of its 160-minute limit.

**For QA:** (1) only one match started and none ended in 600 s, so growth between matches was not read; check the two-hour run gets several (the cap is 900 sim seconds a match). (2) The summary prints "n/a ms at most" for the worst frame: the maximum is not being computed, though the median is.

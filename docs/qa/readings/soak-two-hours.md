# The two-hour soak of the desktop program on ac4ba152 (0.1.1, GW1c), Windows and Linux (QA, path job 14; run 2026-11-25 to 26)

**What it measures.** Stability and memory of the built program over two hours of computer-against-computer matches, headless (RL-279). It is not a flash reading, a frame-rate reading on a screen or a performance budget. Harness: `qa/soak/soak.mjs`; method and limits: `docs/qa/pending/soak/README.md`.

**Runs.**
- **Windows:** Orb's private zip of ac4ba152 (hash checked against its `.sha256.txt`), unpacked into scratch, this PC, below-normal priority. Other sessions' engine jobs ran at times: machine load 25% on average, 56% at most, never 80% or more, in 118 one-minute readings.
- **Linux:** the workflow `linux-soak.yml`, run 45773552777 on ac4ba152, read from the run's log.

## Result: all seven checks pass on both

| | Windows | Linux |
| :--- | :--- | :--- |
| Ran | 7,204 s, quit when asked, exit 0, run marker gone | 7,203 s, the same |
| SCRIPT ERROR lines | none | none |
| Game ticks a second | 60.0 median (5th percentile 59.9) | 60.0 median (59.9) |
| Matches | 13 started, 11 ended: 6 KO, 5 at the 600 s cap | the same counts |
| First match up | 11.6 s | 12.6 s |
| Worst frame (at a match start) | 1,458 ms; median window 31 ms | 1,559 ms; median 23 ms |
| At exit | `10 resources still in use`, 302 objects leaked | `10 resources still in use`, 304 |

## Memory grew, on both, and did not come back down

| MiB, resident (working set) 20 s into the match | m2 | m3 | m4 | m5 | m6 | m7 | m8 | m9 | m10 | m11 | m12 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Windows | 527 | 593 | 611 | 618 | 666 | 693 | 697 | 699 | 745 | 768 | 769 |
| Linux | 384 | 401 | 444 | 464 | 507 | 561 | 566 | 581 | 586 | 598 | 600 |

| | Windows | Linux |
| :--- | :--- | :--- |
| From the 2nd match's start to the end | 527 → 766 (+239) | 384 → 600 (+217) |
| Slope after the 720 s warm-up | 130 MiB an hour | 142 MiB an hour |

**Reading.**
- **No match gives its memory back:** each begins where the last one ended, or a little above.
- On Windows (the only run whose samples I have), of the 239 MiB from the 2nd match's start, about 155 MiB came **during** matches (several matches added nothing, others 11 to 54 MiB in steps) and about 84 MiB **at the match changes** (4 to 16 MiB a change). The first match had already added 97 MiB while it ran.
- Both platforms show it, so it is not one system's allocator alone.
- The engine's counts do not explain it: resources flat (396), nodes flat (about 1,262 to 1,297), no orphans, objects up by a few hundred (at match starts about 37 more a match). That is far too few objects for 220 MiB; the memory is likely in the data inside them (arrays, buffers, stores). **QA has not found where.**
- Whether it levels off is not settled: the last reading rose only 1 to 2 MiB on both, but earlier readings were flat too before the next step. A longer run would say. Performance owns the memory budget; QA sets no pass line.

## Also seen

- **Computer-against-computer matches are long:** the 11 that ended ran 453 to 600+ sim seconds, and 5 of them reached the 600 s cap without a result.
- **The two platforms played the same matches, with one exception.** Matches 3 to 11 ended the same way on both, and every KO among them at the same sim time. Match 2 did not (Windows: KO at 594.0 s; Linux: capped at 600 s). The two runs' first matches had different clock seeds and the game keeps a session intro memory between matches, which may explain it; QA has not checked. This is not a replay or hash comparison.

## Records

`docs/qa/runs/ac4ba152/`: `soak-windows-2h-summary.md`, `soak-windows-2h-samples.csv`, `soak-windows-2h-matches.txt`, `soak-windows-2h-load.txt`, `soak-linux-2h-summary.md` (cut from the run's log; its samples are in the run's `soak-numbers` artifact, not downloaded).

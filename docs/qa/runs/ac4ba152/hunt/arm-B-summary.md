# Soak: 720 s asked, 724 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 350 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=13 wallSeconds=720 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 14 started, at least 6 wanted |

The first match was up 11.2 s after the program started.

**Matches:** 12 ended (capped 12), median 40.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 436.9 | 448.3 | 451.7 | 32.0 |
| private / data | 335.8 | 346.4 | 349.7 | 26.1 |

Warm-up cut: 120 s; 360 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 66 | 17745 | 433.7 | 332.8 |
| 3 | 121 | 17792 | 442.1 | 340.9 |
| 4 | 178 | 17818 | 445.1 | 343.9 |
| 5 | 234 | 17864 | 446.3 | 344.9 |
| 6 | 291 | 17880 | 446.9 | 345.0 |
| 7 | 348 | 17898 | 446.9 | 345.0 |
| 8 | 405 | 17914 | 447.3 | 345.4 |
| 9 | 460 | 17937 | 447.5 | 345.4 |
| 10 | 516 | 17953 | 448.0 | 345.9 |
| 11 | 571 | 17971 | 448.0 | 345.9 |
| 12 | 627 | 17991 | 448.0 | 346.0 |
| 13 | 684 | 18006 | 448.3 | 346.4 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.6), 60.0 process frames a second, worst frame in a window 30.4 ms median, 1381.8 ms at most, process time 17.8 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13409 | 13896 | 18006 |
| nodes | 1262 | 1273 | 1275 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 302 ObjectDB instances were leaked at exit (run with '--verbose' for details).`

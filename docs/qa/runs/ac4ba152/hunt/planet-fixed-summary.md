# Soak: 360 s asked, 364 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 174 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=3 wallSeconds=360 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | not asked of a run this short (4 started) |

The first match was up 10.6 s after the program started.

**Matches:** 2 ended (capped 2), median 130.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 432.7 | 488.2 | 488.2 | 623.5 |
| private / data | 332.0 | 386.1 | 386.1 | 596.2 |

Warm-up cut: 120 s; 181 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 178 | 18069 | 471.4 | 369.4 |
| 3 | 346 | 18118 | n/a | n/a |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 27.4), 60.0 process frames a second, worst frame in a window 30.0 ms median, 1168.4 ms at most, process time 16.2 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13413 | 18160 | 18176 |
| nodes | 1262 | 1273 | 1281 |
| resources | 400 | 400 | 400 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 302 ObjectDB instances were leaked at exit (run with '--verbose' for details).`

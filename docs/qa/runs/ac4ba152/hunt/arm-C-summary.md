# Soak: 900 s asked, 904 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 429 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=16 wallSeconds=900 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 17 started, at least 7 wanted |

The first match was up 11.9 s after the program started.

**Matches:** 15 ended (capped 15), median 40.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 433.3 | 456.0 | 459.7 | 50.5 |
| private / data | 337.4 | 356.0 | 359.7 | 45.4 |

Warm-up cut: 120 s; 450 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 72 | 17685 | 431.3 | 337.4 |
| 3 | 131 | 17761 | 441.3 | 342.0 |
| 4 | 190 | 17799 | 450.2 | 350.8 |
| 5 | 246 | 17839 | 453.9 | 354.5 |
| 6 | 302 | 17879 | 454.7 | 355.1 |
| 7 | 362 | 17905 | 454.8 | 355.1 |
| 8 | 419 | 17937 | 454.9 | 355.0 |
| 9 | 476 | 17966 | 455.0 | 355.0 |
| 10 | 535 | 17989 | 455.4 | 355.5 |
| 11 | 593 | 18030 | 455.9 | 356.1 |
| 12 | 650 | 18038 | 456.0 | 356.0 |
| 13 | 710 | 18067 | 456.0 | 356.0 |
| 14 | 769 | 18094 | 456.0 | 356.0 |
| 15 | 826 | 18121 | 456.0 | 356.0 |
| 16 | 886 | 18135 | n/a | n/a |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 24.9), 59.9 process frames a second, worst frame in a window 30.4 ms median, 1862.4 ms at most, process time 17.8 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13405 | 14064 | 18135 |
| nodes | 1260 | 1273 | 1278 |
| resources | 400 | 400 | 400 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 302 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
